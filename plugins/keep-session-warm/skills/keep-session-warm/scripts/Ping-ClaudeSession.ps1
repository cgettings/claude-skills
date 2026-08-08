<#
.SYNOPSIS
    Sends one no-op resume ping to a Claude Code session, logs the resulting
    cache read/write/cost, and unregisters the scheduled task if the ping
    stopped hitting the session's cache lineage.

    A collapsed read alone does not mean that, though, so it is not the whole
    test: the same numbers are produced when something rewrites the prompt
    prefix under the session, and that case re-warms itself. The API's
    cache_miss_reason tells the two apart, and only the first unregisters.

.DESCRIPTION
    Resumes -SessionId with -Prompt via `claude -p --resume`. When the ping's
    rendered prompt prefix matches the one the target session builds, the call
    is served as a cache read (~0.1x base input rate) and resets the entry's
    1-hour TTL. When it does not match, the call instead writes a brand-new
    prefix at ~2x base rate and refreshes a cache lineage nobody will resume
    into — the failure this script's divergence check exists to catch.

    Two things make the prefixes match, and both are set by the caller rather
    than inferred here: -Entrypoint (the CLAUDE_CODE_ENTRYPOINT the target
    session runs under) and -Effort. Start-ClaudeKeepwarm.ps1 reads both out
    of the session's own transcript and passes them in.

    Every failure mode is caught and logged rather than thrown, because this
    runs unattended from Task Scheduler with no console to report to. Standard
    error is captured to its own file rather than merged into the JSON stream:
    merging makes ConvertFrom-Json throw, which replaces `claude`'s actual
    message ("No conversation found with session ID: ...") with the parser's
    complaint about it.

.PARAMETER SessionId
    The Claude Code session to ping.

.PARAMETER ProjectDir
    Working directory to resume from. Required because --resume only finds a
    session when `claude` runs from the directory that created it — sessions
    are stored per-project under ~/.claude/projects/<mangled-cwd>/, so
    resuming elsewhere looks in a different folder and exits 1 with "No
    conversation found with session ID" (verified 2026-08-07).

.PARAMETER LogPath
    File to append one timestamped result line to per call.

.PARAMETER StatePath
    JSON file holding the cache high-water mark between runs. This is what
    makes the divergence check possible: a healthy ping's cache read only ever
    grows, so a read that collapses below the high-water mark means the prefix
    changed and the pings have switched lineages.

.PARAMETER TaskName
    Scheduled task to unregister when divergence is detected. Omit to make the
    check report-only.

.PARAMETER Entrypoint
    Value to set CLAUDE_CODE_ENTRYPOINT to before invoking `claude`. This is
    the single variable measured to split the cache lineage: on one session,
    same id and directory and seconds apart, an inherited-environment resume
    read 37,950 tokens and wrote 19, while the same resume with the variable
    cleared read 12,424 and wrote 22,150 (verified 2026-08-07). Task Scheduler
    starts processes with a clean environment, so leaving this unset is the
    cleared case.

.PARAMETER Effort
    Effort level to pin via `claude --effort`. Effort is part of the prompt
    cache key, so a ping at a different level maintains its own lineage even
    when the entrypoint matches.

.PARAMETER Prompt
    The no-op prompt sent on each ping.

.PARAMETER ReadDropThreshold
    Fraction of the cache-read high-water mark below which a ping counts as
    diverged. Default 0.5 — the measured divergence dropped the read to 0.33
    of its previous value, and healthy pings never fall at all.

.PARAMETER MinWriteTokens
    A ping must also write more than this many tokens to count as diverged,
    so a small session whose reads legitimately wobble cannot trip the check.
    Default 4096 — the largest per-model minimum cacheable prefix in Anthropic's
    prompt-caching documentation as read 2026-08-07, so a write below it cannot
    represent a meaningful rewrite on any model.

.PARAMETER MaxResets
    How many prefix rewrites to absorb over the life of the keepwarm before
    stopping anyway. Counted in total, not consecutively, and carried in the
    state file.

    This is a spend cap, not a correctness control. Continuing through a rewrite
    is right when rewrites are occasional, because the ping that paid for one
    has re-warmed the new prefix. It stops being right if the prefix keeps
    moving: every rewrite is billed at full prefix rate — $0.39 on a 59K-token
    session, and a recorded 363,713-token rewrite on a large one cost ~$3.64 —
    so an uncapped keepwarm could buy one every interval all night and log each
    as a healthy line. Default 3.

.EXAMPLE
    & .\Ping-ClaudeSession.ps1 -SessionId 'd6f79d29-...' -ProjectDir 'C:\src\app' -LogPath 'C:\temp\ping.log'

    Send a single manual ping. Useful to sanity-check a session/directory
    pairing, or to read the cache numbers back before trusting a schedule to
    it. Without -Entrypoint this reproduces the diverged case on purpose,
    which is what /keepwarm-check uses it for.

.OUTPUTS
    PSCustomObject with Status, CacheRead, CacheWrite, CostUsd, and Detail.

    Status is one of BASE (high-water mark established), OK (healthy read),
    RESET (the prefix was rewritten by something outside this keepwarm; the
    mark was re-baselined and the schedule left running), MISS (the lineage
    diverged; the task unregistered itself), or ERROR (the ping never landed).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SessionId,
    [Parameter(Mandatory)][string]$ProjectDir,
    [Parameter(Mandatory)][string]$LogPath,
    [string]$StatePath,
    [string]$TaskName,
    [string]$Entrypoint,
    [ValidateSet('low', 'medium', 'high', 'xhigh', 'max')][string]$Effort,
    [string]$Prompt = 'Acknowledge and take no action.',
    [double]$ReadDropThreshold = 0.5,
    [int]$MinWriteTokens = 4096,
    [int]$MaxResets = 3
)

# PowerShell 7.3+ can turn native stderr into a terminating error depending on
# $ErrorActionPreference. Exit codes are checked explicitly below, so opt out
# where the variable exists rather than letting the host decide.
if (Test-Path Variable:\PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}

# Stamp the whole run once, so the log line and the state file agree on when
# this ping happened.
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

# Two local helpers, used by every exit path below: one appends a log line, the
# other builds the object this script returns.
function Write-PingLog {
    param([string]$Line)
    Add-Content -LiteralPath $LogPath -Value $Line -Encoding utf8
}

function New-PingResult {
    param([string]$Status, [int]$Read, [int]$Write, [double]$Cost, [string]$Detail)
    [PSCustomObject]@{
        Timestamp  = $timestamp
        Status     = $Status
        CacheRead  = $Read
        CacheWrite = $Write
        CostUsd    = $Cost
        Detail     = $Detail
    }
}

# Get-CacheMissReason lives in its own file so it can be dot-sourced and
# replayed against real transcripts without sending a ping. A missing file
# leaves the function undefined, which the miss path below treats as an
# unknown reason — the conservative branch.
$reasonHelper = Join-Path $PSScriptRoot 'Get-CacheMissReason.ps1'
if (Test-Path -LiteralPath $reasonHelper) { . $reasonHelper }

# STEP 1 — move into the project directory.
# --resume resolves the session relative to the current directory, so this must
# happen before `claude` is invoked and cannot be left to the task's own
# -WorkingDirectory. -LiteralPath so a project path containing [ or ] resolves.
try {
    Set-Location -LiteralPath $ProjectDir -ErrorAction Stop
} catch {
    $detail = "cannot enter ProjectDir '$ProjectDir': $($_.Exception.Message)"
    Write-PingLog "$timestamp ERROR $detail"
    return New-PingResult -Status 'ERROR' -Read 0 -Write 0 -Cost 0 -Detail $detail
}

# STEP 2 — pin the first lineage key, the entrypoint.
# Set it explicitly either way. Task Scheduler supplies a clean environment, but
# a hand-run ping inherits the caller's — so leaving this to inheritance makes
# the result depend on who invoked it, which is exactly what a lineage probe
# must not do.
if ($Entrypoint) {
    $env:CLAUDE_CODE_ENTRYPOINT = $Entrypoint
} else {
    Remove-Item Env:CLAUDE_CODE_ENTRYPOINT -ErrorAction SilentlyContinue
}

# STEP 3 — build the command line, pinning the second lineage key (effort).
$claudeArgs = @('-p', '--resume', $SessionId, $Prompt, '--output-format', 'json')
if ($Effort) { $claudeArgs += @('--effort', $Effort) }

# Somewhere to put stderr so it stays out of the JSON on stdout.
$stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) "claude-ping-$SessionId.err"

# STEP 4 — send the ping. This is the only line that costs money.
try {
    # --output-format json is what exposes usage.cache_read_input_tokens /
    # cache_creation_input_tokens / total_cost_usd, the fields the divergence
    # check reads. stderr goes to its own file so a warning on it cannot
    # corrupt the JSON on stdout.
    $stdout = & claude @claudeArgs 2>$stderrPath
    $exitCode = $LASTEXITCODE
} catch {
    $detail = "invoking claude failed: $($_.Exception.Message)"
    Write-PingLog "$timestamp ERROR $detail"
    return New-PingResult -Status 'ERROR' -Read 0 -Write 0 -Cost 0 -Detail $detail
}

# STEP 5 — three failure gates, in order: crashed, refused, or lied.
# Read stderr back and delete it; this is what carries claude's own message.
$stderrText = ''
if (Test-Path -LiteralPath $stderrPath) {
    $stderrText = (Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue)
    if ($stderrText) { $stderrText = $stderrText.Trim() }
    Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
}

# Gate 1: non-zero exit — e.g. the session wasn't found from this directory.
if ($exitCode -ne 0) {
    $detail = "exit=$exitCode $stderrText"
    Write-PingLog "$timestamp ERROR $detail"
    return New-PingResult -Status 'ERROR' -Read 0 -Write 0 -Cost 0 -Detail $detail
}

# Gate 2: output that isn't JSON. Log a truncated sample so it can be diagnosed.
try {
    $result = $stdout | ConvertFrom-Json -ErrorAction Stop
} catch {
    $raw = ($stdout | Out-String).Trim()
    if ($raw.Length -gt 200) { $raw = $raw.Substring(0, 200) + '...' }
    $detail = "unparseable output: $raw"
    Write-PingLog "$timestamp ERROR $detail"
    return New-PingResult -Status 'ERROR' -Read 0 -Write 0 -Cost 0 -Detail $detail
}

# Gate 3: valid JSON that reports failure anyway.
# A well-formed response can still report failure. Exit code alone misses this.
if ($result.is_error -or $result.subtype -ne 'success') {
    $detail = "subtype=$($result.subtype) is_error=$($result.is_error) $($result.result)"
    Write-PingLog "$timestamp ERROR $detail"
    return New-PingResult -Status 'ERROR' -Read 0 -Write 0 -Cost 0 -Detail $detail
}

# STEP 6 — pull out the three numbers everything downstream is judged on.
$read = [int]$result.usage.cache_read_input_tokens
$write = [int]$result.usage.cache_creation_input_tokens
$cost = [double]$result.total_cost_usd
$measurements = "read=$read write=$write cost=`$$([math]::Round($cost, 4))"

# STEP 7 — load the high-water mark from the previous ping, if there is one.
# A corrupt state file is treated as absent rather than fatal.
$state = $null
if ($StatePath -and (Test-Path -LiteralPath $StatePath)) {
    try {
        $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        $state = $null
    }
}

# STEP 8a — no baseline yet: record this read as the mark and stop.
# Normally Start-ClaudeKeepwarm seeds the mark from its probe, so this branch
# only runs for a hand-invoked ping.
# First ping establishes the high-water mark. It is expected to write more than
# later pings — it carries whatever turns accumulated since the session's last
# request — so it can never itself count as diverged.
if ($null -eq $state -or $null -eq $state.MaxRead) {
    Write-PingLog "$timestamp BASE  $measurements (baseline established)"
    if ($StatePath) {
        [PSCustomObject]@{
            SessionId  = $SessionId
            MaxRead    = $read
            PingCount  = 1
            ResetCount = 0
            FirstPing  = $timestamp
        } | ConvertTo-Json | Set-Content -LiteralPath $StatePath -Encoding utf8
    }
    return New-PingResult -Status 'BASE' -Read $read -Write $write -Cost $cost -Detail 'baseline established'
}

# STEP 8b — the divergence test. Both halves must hold: the read collapsed
# (we are no longer reading the chain we were), AND the write is large enough
# to mean a real rewrite rather than a small session's noise.
$maxRead = [int]$state.MaxRead
$diverged = ($read -lt ($maxRead * $ReadDropThreshold)) -and ($write -gt $MinWriteTokens)

# A miss is detected by the numbers above, then classified by the reason the
# API gave for it — because the two outcomes are opposite. A diverged lineage
# means continuing would spend the night refreshing a chain nobody will resume
# into. A rewritten prefix means this very ping re-warmed the new one, and
# stopping would throw away every hour that remains.
if ($diverged) {
    $dropPercent = [math]::Round((1 - ($read / [double]$maxRead)) * 100, 1)
    $reason = if (Get-Command Get-CacheMissReason -ErrorAction SilentlyContinue) {
        Get-CacheMissReason -Read $read -Write $write -SessionId $SessionId -ProjectDir $ProjectDir
    } else { $null }

    # Measured over 217 transcripts / 25,675 assistant records on 2026-08-08: of
    # 23 system_changed and 63 tools_changed misses, every one whose session had
    # a following request had that request read the new prefix back from cache.
    #
    # This is the branch a keepwarm needs most, because what triggers it is
    # nothing the keepwarm controls or can predict: a server-side tool-roster
    # flip mid-gap rewrites the system prompt text, and unregistering on that
    # forfeits the rest of the night to save a single ping.
    $resetCount = [int]$state.ResetCount + 1
    if (($reason -in @('system_changed', 'tools_changed')) -and $resetCount -le $MaxResets) {
        $detail = "prefix rewritten ($reason): read fell $dropPercent% below high-water $maxRead; re-baselined and continuing (reset $resetCount of $MaxResets)"
        Write-PingLog "$timestamp RESET $measurements  $detail"

        # Re-baseline to the write, not the read. What this ping paid to write
        # IS the prefix later pings will read, so carrying the old mark forward
        # would make the next perfectly healthy ping look diverged in turn.
        if ($StatePath) {
            [PSCustomObject]@{
                SessionId  = $SessionId
                MaxRead    = $write
                PingCount  = [int]$state.PingCount + 1
                ResetCount = $resetCount
                FirstPing  = $state.FirstPing
            } | ConvertTo-Json | Set-Content -LiteralPath $StatePath -Encoding utf8
        }

        return New-PingResult -Status 'RESET' -Read $read -Write $write -Cost $cost -Detail $detail
    }

    # Everything else takes the task down, including an absent or unrecognised
    # reason. Failure-closed on purpose: `unavailable` is not a miss signal at
    # all (median read-drop 0%, minimum -89% — the read grew), and the field is
    # missing outright on some genuine misses, so no unproven value gets to buy
    # a reprieve here.
    # One case reaching here is not a divergence: a rewrite reason that has run
    # out of budget. Continuing is only correct while the rewrites are
    # occasional — each one is billed at full prefix rate, so a prefix that
    # keeps moving turns "keep the session warm" into an open tab. Past the
    # budget the keepwarm stops and says why, rather than quietly buying
    # another rewrite every interval for the rest of the night.
    $because = if ($reason -in @('system_changed', 'tools_changed')) {
        "reset budget exhausted after $MaxResets rewrite(s), latest $reason"
    } elseif ($reason) {
        "lineage diverged ($reason)"
    } else {
        'lineage diverged'
    }
    $detail = "${because}: read fell $dropPercent% below high-water $maxRead"
    $line = "$timestamp MISS  $measurements  $detail"

    if ($TaskName) {
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            $line += "; unregistered '$TaskName'"
        } catch {
            $line += "; FAILED to unregister '$TaskName': $($_.Exception.Message)"
        }
    }

    Write-PingLog $line
    return New-PingResult -Status 'MISS' -Read $read -Write $write -Cost $cost -Detail $detail
}

# STEP 9 — healthy ping. Log it and raise the high-water mark.
Write-PingLog "$timestamp OK    $measurements"

# Max() rather than assignment: the mark should only ever climb, which is the
# property the divergence test in step 8b depends on.
if ($StatePath) {
    # ResetCount is carried, not recomputed. The budget is a total over the
    # keepwarm's life, so a healthy ping in between two rewrites must not
    # quietly refill it.
    [PSCustomObject]@{
        SessionId  = $SessionId
        MaxRead    = [math]::Max($maxRead, $read)
        PingCount  = [int]$state.PingCount + 1
        ResetCount = [int]$state.ResetCount
        FirstPing  = $state.FirstPing
    } | ConvertTo-Json | Set-Content -LiteralPath $StatePath -Encoding utf8
}

return New-PingResult -Status 'OK' -Read $read -Write $write -Cost $cost -Detail ''
