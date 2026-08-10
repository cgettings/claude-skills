<#
.SYNOPSIS
    Registers a scheduled task that keeps a Claude Code session's prompt cache
    warm, pinned to the same cache lineage the session itself uses.

.DESCRIPTION
    Registers a Windows scheduled task running Ping-ClaudeSession.ps1 every
    -IntervalMinutes. Each ping is a cache read against the session's existing
    prefix (~0.1x base input rate) that resets the 1-hour TTL, so the session
    never falls off the cache and forces a full rewrite (~2x base rate) on the
    next resume.

    That only holds while the ping's rendered prompt prefix matches the
    session's. Two things break the match, and this script pins both by
    reading them out of the session's own transcript:

      * CLAUDE_CODE_ENTRYPOINT — Task Scheduler starts processes with a clean
        environment, which renders a different harness preamble. Measured
        2026-08-07 on one session, same id and directory, seconds apart: with
        the variable inherited, a resume read 37,950 tokens and wrote 19;
        with it cleared, the same resume read 12,424 and wrote 22,150. The
        readable prefix collapses inside the tools/system region, so the whole
        message history downstream is invalidated. Restoring just that one
        variable restored the lineage exactly (read 37,969 — precisely where
        the inherited-environment chain had left off).
      * Effort level, which is part of the prompt cache key.

    Registration is gated on a live probe. Before creating the task this sends
    one ping with the keys it is about to pin and refuses to register if that
    ping does not land on the session's lineage — a keepwarm measured as broken
    is worse than none, because it spends the night at rewrite prices while
    logging success. Pass -SkipCheck to register unconditionally.

    A power pre-flight runs first, and costs nothing: a scheduled task cannot
    ping a sleeping machine unless a wake timer fires it, and the wake-timer
    setting is per-power-source. On the machine this was built for (measured
    2026-08-07) it is enabled on AC and disabled on battery, which makes
    -WakeToRun inert while unplugged — but that is one machine's power plan,
    not a Windows default, which is why the check reads the setting rather
    than assuming it.

    The task expires and self-deletes -DurationHours after it starts. If you
    resume the session interactively before then, run Stop-ClaudeKeepwarm.ps1
    first: the scheduled ping and the live session both append to the same
    transcript file, and nothing coordinates those two writers.

.PARAMETER SessionId
    The session to keep warm. Defaults to $env:CLAUDE_CODE_SESSION_ID, so
    calling this from inside the session you are about to leave just works.

.PARAMETER ProjectDir
    The directory the session was created in. Defaults to the current
    directory. Must be a real Windows path — a Bash tool's /tmp is not C:\tmp.

.PARAMETER IntervalMinutes
    Minutes between pings. Must stay under 60 (the cache TTL) with margin for
    scheduler jitter; 55 is the default and is what has been tested.

.PARAMETER DurationHours
    Hours of pinging before the task expires and deletes itself. Typed
    [double] so fractional hours work.

.PARAMETER Effort
    Override the effort level pinned on each ping. Defaults to the level the
    session's most recent turn ran at, read from its transcript.

.PARAMETER Entrypoint
    Override CLAUDE_CODE_ENTRYPOINT for the pings. Defaults to the value the
    session's most recent turn recorded.

.PARAMETER Prompt
    The no-op prompt sent on every ping. May not contain a double quote, since
    it is embedded in the scheduled task's argument string.

.PARAMETER SkipCheck
    Register without probing the cache lineage first.

    The probe is on by default because the running keepwarm cannot replace it.
    Ping-ClaudeSession.ps1 detects a divergence by watching the cache read fall
    below a high-water mark, and the first ping is what establishes that mark —
    so a keepwarm that was on the wrong lineage from its very first ping seeds
    the mark from the wrong number and reports OK all night. The probe covers
    exactly that case, and it has to run now: it is diagnostic because the
    session's cache is still hot from live use, whereas 55 minutes later a
    lapsed cache and a diverged lineage produce the same numbers.

    Its read also seeds the high-water mark, so the first scheduled ping is
    judged against a measurement rather than against itself.

.EXAMPLE
    & .\Start-ClaudeKeepwarm.ps1

    Protect the current session for the default 9 hours, reading session id
    from the environment and directory, entrypoint, and effort from context.

.EXAMPLE
    & .\Start-ClaudeKeepwarm.ps1 -DurationHours 11 -IntervalMinutes 50

    A longer night with more margin for scheduler jitter.

.OUTPUTS
    PSCustomObject describing the registered task, the pinned lineage keys, the
    probe verdict, and the estimated ping count.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SessionId = $env:CLAUDE_CODE_SESSION_ID,
    [string]$ProjectDir = (Get-Location).Path,
    [ValidateRange(1, 59)][int]$IntervalMinutes = 55,
    [ValidateRange(0.05, 72)][double]$DurationHours = 9,
    [ValidateSet('low', 'medium', 'high', 'xhigh', 'max')][string]$Effort,
    [string]$Entrypoint,
    [string]$Prompt = 'Acknowledge and take no action.',
    [switch]$SkipCheck
)

$ErrorActionPreference = 'Stop'

# STEP 1 — argument checks that can fail without touching anything.
if (-not $SessionId) {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new('No -SessionId given and CLAUDE_CODE_SESSION_ID is not set. Pass -SessionId explicitly.'),
            'SessionIdMissing', [System.Management.Automation.ErrorCategory]::InvalidArgument, $null))
}

# The prompt is embedded in a quoted argument string, so a quote inside it would
# terminate that string and corrupt the task's command line.
if ($Prompt -match '"') {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentException]::new('-Prompt may not contain a double quote; it is embedded in the scheduled task argument string.'),
            'PromptQuoting', [System.Management.Automation.ErrorCategory]::InvalidArgument, $Prompt))
}

# STEP 2 — find the session and read its two lineage keys. Dot-sourcing brings
# Resolve-ClaudeSessionContext into this scope; the sibling script only defines
# a function, it does not run anything.
$scriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDir 'Resolve-ClaudeSessionContext.ps1')

try {
    $context = Resolve-ClaudeSessionContext -SessionId $SessionId -ProjectDir $ProjectDir
} catch {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.IO.FileNotFoundException]::new($_.Exception.Message),
            'TranscriptNotFound', [System.Management.Automation.ErrorCategory]::ObjectNotFound, $SessionId))
}

# Explicit parameters win; anything not given falls back to what was detected.
$ProjectDir = $context.ProjectDir
if (-not $Entrypoint) { $Entrypoint = $context.Entrypoint }
# Guard the assignment, not just the use. Line ~233 below already omits -Effort
# from the probe splat when it is empty, for exactly this reason — but an
# unguarded assignment here throws first: PowerShell enforces a ValidateSet on
# every assignment to the parameter variable, not only at binding, so resolving
# a session that records no effort ($null) fails before that splat is reached.
# Sessions created by `claude -p` record no effort field at all (verified
# 2026-08-09, CLI 2.1.220).
if (-not $Effort -and $context.Effort) { $Effort = $context.Effort }

if (-not $Entrypoint) {
    Write-Warning 'Could not read CLAUDE_CODE_ENTRYPOINT from the transcript. Pings will run with a clean environment, which is the measured cache-divergence case. Pass -Entrypoint explicitly.'
}

# STEP 3 — power pre-flight. Helper first, then the two settings it reads.
function Get-PowerSettingIndex {
    <#
    .SYNOPSIS
        Reads one powercfg sleep-subgroup setting for the active power source.

    .OUTPUTS
        Int32, or $null when the setting could not be read.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Setting,
        [Parameter(Mandatory)][ValidateSet('AC', 'DC')][string]$PowerSource
    )
    # powercfg prints one "Current AC/DC Power Setting Index: 0x..." line per
    # source; pull the hex value for the source asked for and convert it.
    try {
        $raw = powercfg /query SCHEME_CURRENT SUB_SLEEP $Setting 2>$null
        $match = $raw | Select-String -Pattern "Current $PowerSource Power Setting Index:\s*0x([0-9a-fA-F]+)"
        if ($match) { return [Convert]::ToInt32($match.Matches[0].Groups[1].Value, 16) }
    } catch {
        # Power policy is advisory here — a machine that cannot be inspected is
        # not a reason to refuse to schedule.
    }
    return $null
}

# Power pre-flight runs before anything is paid for. A scheduled task cannot
# ping a sleeping machine unless a wake timer fires it, and both settings differ
# between AC and battery — on the machine this was built for, wake timers are
# enabled on AC and disabled on battery, so -WakeToRun is inert while unplugged.
# No battery means a desktop, which is always on AC; BatteryStatus 2 means
# plugged in. Which of the two settings applies depends on the answer.
$battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
$onAc = (-not $battery) -or [bool](@($battery | Where-Object { $_.BatteryStatus -eq 2 }).Count)
$powerSource = if ($onAc) { 'AC' } else { 'DC' }
$sleepAfter = Get-PowerSettingIndex -Setting 'STANDBYIDLE' -PowerSource $powerSource
$wakeTimers = Get-PowerSettingIndex -Setting 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d' -PowerSource $powerSource

# The fatal combination: the machine will sleep, and nothing is allowed to wake
# it. Warn rather than refuse — this is a prediction, not a measurement.
if ($sleepAfter -gt 0 -and $wakeTimers -eq 0) {
    Write-Warning ("On {0} power this machine sleeps after {1} minute(s) and wake timers are disabled, so the task cannot wake it. Pings will stop at the first sleep. Plug in, or enable wake timers for the active power plan." -f
        $powerSource, [math]::Round($sleepAfter / 60))
} elseif (-not $onAc) {
    Write-Warning 'Running on battery. Scheduled pings are far more fragile unplugged — prefer AC for an overnight keepwarm.'
}

# STEP 4 — settle the paths the task will use. The ping script must exist now,
# because a task pointing at a missing file fails silently at 3am.
$pingScript = Join-Path $scriptDir 'Ping-ClaudeSession.ps1'
if (-not (Test-Path -LiteralPath $pingScript)) {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.IO.FileNotFoundException]::new("Ping-ClaudeSession.ps1 not found beside this script at '$pingScript'."),
            'PingScriptNotFound', [System.Management.Automation.ErrorCategory]::ObjectNotFound, $pingScript))
}

# One task per session id, so a second keepwarm never collides with this one.
$taskName = "ClaudeKeepwarm-$SessionId"
$logPath = Join-Path $env:TEMP "claude-keepwarm-$SessionId.log"
$statePath = Join-Path $env:TEMP "claude-keepwarm-$SessionId.state.json"

# The state file holds the cache high-water mark. A stale one from a previous
# night would make the first ping look like a divergence.
Remove-Item -LiteralPath $statePath -Force -ErrorAction SilentlyContinue

# STEP 5 — the gate. Probe the lineage for real, refuse to register if it does
# not land, and seed the high-water mark from what it measured.
$probe = $null
# ShouldProcess gates the probe as well as the registration, so -WhatIf costs
# nothing: the probe is a real API call, not a local calculation.
if (-not $SkipCheck.IsPresent -and $PSCmdlet.ShouldProcess($SessionId, 'Probe cache lineage (one cache read)')) {
    # Splatting, because -Effort has a ValidateSet an empty string would fail.
    $probeArgs = @{ SessionId = $SessionId; ProjectDir = $ProjectDir }
    if ($Entrypoint) { $probeArgs['Entrypoint'] = $Entrypoint }
    if ($Effort) { $probeArgs['Effort'] = $Effort }

    $probe = & (Join-Path $scriptDir 'Test-ClaudeCacheLineage.ps1') @probeArgs

    if ($probe.Verdict -in @('Diverged', 'ProbeFailed')) {
        # Refuse rather than register. A keepwarm measured as landing on the
        # wrong lineage would spend the night at rewrite prices and still leave
        # the session cold, and it would do it while reporting OK.
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new(
                    "Not registering: cache lineage probe returned '$($probe.Verdict)'. $($probe.Advice)$($probe.Detail)"),
                'LineageProbeFailed', [System.Management.Automation.ErrorCategory]::InvalidResult, $probe))
    }

    # Seed the high-water mark from the probe so the first scheduled ping is
    # judged against a measurement instead of establishing its own baseline.
    [PSCustomObject]@{
        SessionId = $SessionId
        MaxRead   = $probe.CacheRead
        PingCount = 1
        FirstPing = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    } | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
}

# STEP 6 — build the scheduled task: which shell, what command line, what
# trigger, what settings.
# Prefer pwsh where present: it is what the session itself runs under, and
# powershell.exe is Windows PowerShell 5.1, a runtime this is not tested on.
$psHost = $null
$pwshCommand = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if ($pwshCommand) { $psHost = $pwshCommand.Source }
if (-not $psHost) { $psHost = (Get-Command powershell.exe -ErrorAction Stop).Source }

# The task stores one flat command-line string, so every value that could
# contain a space is quoted here. The `" is an escaped double quote.
$argParts = @(
    '-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden'
    '-File', "`"$pingScript`""
    '-SessionId', $SessionId
    '-ProjectDir', "`"$ProjectDir`""
    '-LogPath', "`"$logPath`""
    '-StatePath', "`"$statePath`""
    '-TaskName', "`"$taskName`""
    '-Prompt', "`"$Prompt`""
)
# Both lineage keys are passed to the ping rather than left to the environment.
if ($Entrypoint) { $argParts += @('-Entrypoint', "`"$Entrypoint`"") }
if ($Effort) { $argParts += @('-Effort', $Effort) }

$action = New-ScheduledTaskAction -Execute $psHost -Argument ($argParts -join ' ') -WorkingDirectory $ProjectDir

# Fire one interval from now, then repeat at that interval until the window ends.
$start = (Get-Date).AddMinutes($IntervalMinutes)
$end = $start.AddHours($DurationHours)

$trigger = New-ScheduledTaskTrigger -Once -At $start `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -RepetitionDuration ([TimeSpan]::FromHours($DurationHours))

# RepetitionDuration stops new firings but does not mark the trigger expired;
# EndBoundary is what DeleteExpiredTaskAfter keys off to remove the task.
$trigger.EndBoundary = $end.ToString('s')

# -AllowStartIfOnBatteries is the one that matters on a laptop.
# -DontStopIfGoingOnBatteries only governs stopping an already-running task;
# DisallowStartIfOnBatteries defaults to True independently, and a task with
# it set simply never starts while unplugged.
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -WakeToRun `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
    -DeleteExpiredTaskAfter (New-TimeSpan -Minutes 5)

# Written into the task so Task Scheduler itself shows what this is and why.
$description = "Claude prompt-cache keepwarm for session $SessionId in $ProjectDir. Pings every $IntervalMinutes min as entrypoint '$Entrypoint' at effort '$Effort'; expires $end."

# STEP 7 — register, then report. -Force replaces an existing task for this same
# session rather than erroring on the duplicate name.
if (-not $PSCmdlet.ShouldProcess($taskName, 'Register scheduled task')) { return }

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
    -Description $description -Force | Out-Null

$pingCount = [math]::Floor(($DurationHours * 60) / $IntervalMinutes)

# A ping costs a cache read (0.1x base input) against a rewrite's 2x, so ~20
# pings spend what the rewrite they avoid would have cost.
if ($pingCount -gt 20) {
    Write-Warning "$pingCount pings exceeds the ~20-ping break-even against a single full-prefix rewrite. Shorten -DurationHours or widen -IntervalMinutes unless you want the warm resume for latency rather than cost."
}

[PSCustomObject]@{
    TaskName        = $taskName
    SessionId       = $SessionId
    ProjectDir      = $ProjectDir
    Entrypoint      = $Entrypoint
    Effort          = $Effort
    IntervalMinutes = $IntervalMinutes
    FirstPing       = $start
    ExpiresAt       = $end
    EstimatedPings  = $pingCount
    Verdict         = if ($probe) { $probe.Verdict } else { 'NotChecked' }
    ProbeRead       = if ($probe) { $probe.CacheRead } else { $null }
    ProbeCostUsd    = if ($probe) { $probe.CostUsd } else { $null }
    OnACPower       = $onAc
    LogPath         = $logPath
    StatePath       = $statePath
    PowerShellHost  = $psHost
}
