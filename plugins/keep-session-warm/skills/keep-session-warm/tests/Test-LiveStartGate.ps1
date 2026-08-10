<#
.SYNOPSIS
    Proves Start-ClaudeKeepwarm.ps1 registers a real scheduled task on a
    matching lineage, refuses to register when the probe fails, and still
    rejects bad arguments without touching the API. THIS ONE SPENDS MONEY and
    registers real Windows Scheduled Tasks.

.DESCRIPTION
    Four cases against one throwaway session.

    Case 2 is a recorded null, not a pass in the original sense. The plan asked
    for a `Diverged` probe verdict driven by a mismatched CLAUDE_CODE_ENTRYPOINT;
    that verdict cannot be produced against a `claude -p` session, because
    neither lineage key moves the prefix such a session renders (measured
    2026-08-09 across three throwaways — see PLAN-live-test-coverage.md). So
    case 2 asserts what actually happens: Start registers anyway. That is the
    finding worth having, because it means the gate does not protect against a
    wrong entrypoint on this class of session.

    Case 3 still reaches the refusal branch, by the other route into it.
    Start-ClaudeKeepwarm.ps1 throws `LineageProbeFailed` on `Diverged` OR
    `ProbeFailed`, and `ProbeFailed` is what the probe returns when the ping
    itself errors. Shadowing `claude` on PATH with a stub that exits non-zero
    produces exactly that, deterministically and for no tokens. The gate cannot
    tell why the probe failed, so this exercises the same throw.

    Ground rule 2: the set of pre-existing ClaudeKeepwarm-* tasks is snapshotted
    before anything registers and re-checked at the end. This script only ever
    unregisters the task named for its own throwaway session.

.PARAMETER MaxSpendUsd
    Aborts before any case that would push cumulative cost past this.

.EXAMPLE
    & .\Test-LiveStartGate.ps1

.OUTPUTS
    One line per assertion, then a PASS/FAIL total. Exits 1 on any failure.
#>
[CmdletBinding()]
param(
    [double]$MaxSpendUsd = 1.00
)

$ErrorActionPreference = 'Stop'

$testsDir = $PSScriptRoot
$scriptsDir = Join-Path (Split-Path -Parent $testsDir) 'scripts'
$startScript = Join-Path $scriptsDir 'Start-ClaudeKeepwarm.ps1'
$stopScript = Join-Path $scriptsDir 'Stop-ClaudeKeepwarm.ps1'
. (Join-Path $testsDir 'New-ThrowawaySession.ps1')

$spent = 0.0
$pass = 0
$fail = 0
$session = $null
$stubDir = $null
$originalPath = $env:PATH

function Assert-That {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) { $script:pass++ } else { $script:fail++ }
    '{0,-52} {1} {2}' -f $Name, $(if ($Condition) { 'ok' } else { 'FAIL' }), $Detail
}

# Ground rule 2 — snapshot foreign tasks BEFORE anything is registered.
$foreignTasksBefore = @(Get-ScheduledTask -TaskName 'ClaudeKeepwarm-*' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty TaskName | Sort-Object)
"Foreign ClaudeKeepwarm-* tasks before: $(if ($foreignTasksBefore) { $foreignTasksBefore -join ', ' } else { '(none)' })"

try {
    $session = New-ThrowawaySession -MaxSpendUsd $MaxSpendUsd
    $spent += $session.CostUsd
    $taskName = "ClaudeKeepwarm-$($session.SessionId)"
    $statePath = Join-Path $env:TEMP "claude-keepwarm-$($session.SessionId).state.json"
    "Throwaway: $($session.SessionId) model=$($session.Model) createCost=`$$($session.CostUsd)"
    ''

    $startArgs = @{
        SessionId       = $session.SessionId
        ProjectDir      = $session.ProjectDir
        Effort          = $session.Effort
        IntervalMinutes = 1
        DurationHours   = 0.1
    }

    # --- Case 1: registers on a matching lineage. Must run first (ordering
    # hazard: it establishes what the session's own lineage reads).
    '--- case 1: registers on a matching lineage'
    $r1 = & $startScript @startArgs -Entrypoint $session.Entrypoint
    $spent += [double]$r1.ProbeCostUsd
    Assert-That 'case1 verdict is Warm/WarmWithBacklog' ($r1.Verdict -in @('Warm', 'WarmWithBacklog')) "verdict=$($r1.Verdict) read=$($r1.ProbeRead)"
    Assert-That 'case1 scheduled task now exists' ([bool](Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) $taskName
    Assert-That 'case1 state file exists' (Test-Path -LiteralPath $statePath)
    $state1 = if (Test-Path -LiteralPath $statePath) { Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json } else { $null }
    Assert-That 'case1 state MaxRead equals ProbeRead' ($null -ne $state1 -and [int]$state1.MaxRead -eq [int]$r1.ProbeRead) "MaxRead=$($state1.MaxRead) ProbeRead=$($r1.ProbeRead)"
    Assert-That 'case1 EstimatedPings is 6' ($r1.EstimatedPings -eq 6) "EstimatedPings=$($r1.EstimatedPings)"

    $stop1 = & $stopScript -SessionId $session.SessionId -PassThru
    Assert-That 'case1 Stop reports Unregistered' ($stop1.Action -eq 'Unregistered') "Action=$($stop1.Action)"
    Assert-That 'case1 task gone after Stop' (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue))
    ''

    # --- Case 2: a mismatched entrypoint does NOT stop registration. Recorded
    # null — see the .DESCRIPTION above.
    '--- case 2: mismatched entrypoint does not trip the gate (recorded null)'
    if ($spent -gt $MaxSpendUsd) { throw "Spend cap exceeded before case 2: `$$([math]::Round($spent, 4)) > `$$MaxSpendUsd" }
    $r2 = & $startScript @startArgs -Entrypoint 'keepwarm-live-divergence-probe'
    $spent += [double]$r2.ProbeCostUsd
    Assert-That 'case2 probe did NOT report Diverged' ($r2.Verdict -ne 'Diverged') "verdict=$($r2.Verdict) read=$($r2.ProbeRead)"
    Assert-That 'case2 registered despite wrong entrypoint' ([bool](Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) 'gate does not protect against this'
    & $stopScript -SessionId $session.SessionId | Out-Null
    Assert-That 'case2 task cleaned up' (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue))
    ''

    # --- Case 3: the refusal branch, reached via ProbeFailed. No API call: the
    # stub exits before `claude` would do anything.
    '--- case 3: refuses to register when the probe fails'
    $stubDir = Join-Path $env:TEMP "keepwarm-stub-$PID-$(Get-Random -Minimum 1000 -Maximum 9999)"
    New-Item -ItemType Directory -Force -Path $stubDir | Out-Null
    # A .cmd shadowing `claude` on PATH. Ping-ClaudeSession.ps1 invokes bare
    # `claude`, so PATH order decides which one runs.
    Set-Content -LiteralPath (Join-Path $stubDir 'claude.cmd') -Value '@exit /b 1' -Encoding ascii
    $env:PATH = "$stubDir;$originalPath"

    $threw = $false
    $errorId = ''
    try {
        & $startScript @startArgs -Entrypoint $session.Entrypoint | Out-Null
    } catch {
        $threw = $true
        $errorId = $_.FullyQualifiedErrorId
    } finally {
        $env:PATH = $originalPath
    }
    Assert-That 'case3 Start threw' $threw
    Assert-That 'case3 error id is LineageProbeFailed' ($errorId -like '*LineageProbeFailed*') "errorId=$errorId"
    Assert-That 'case3 registered NO scheduled task' (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue))
    Assert-That 'case3 wrote NO state file' (-not (Test-Path -LiteralPath $statePath))
    ''

    # --- Case 4: argument gates. Neither reaches the API.
    '--- case 4: argument gates fire before anything is touched'
    $threw = $false; $errorId = ''
    try { & $startScript @startArgs -Entrypoint $session.Entrypoint -Prompt 'say "hi"' | Out-Null }
    catch { $threw = $true; $errorId = $_.FullyQualifiedErrorId }
    Assert-That 'case4 quoted -Prompt throws PromptQuoting' ($threw -and $errorId -like '*PromptQuoting*') "errorId=$errorId"

    $unusedGuid = [guid]::NewGuid().ToString()
    $threw = $false; $errorId = ''
    try { & $startScript -SessionId $unusedGuid -ProjectDir $session.ProjectDir -IntervalMinutes 1 -DurationHours 0.1 | Out-Null }
    catch { $threw = $true; $errorId = $_.FullyQualifiedErrorId }
    Assert-That 'case4 unknown session throws TranscriptNotFound' ($threw -and $errorId -like '*TranscriptNotFound*') "errorId=$errorId"
    Assert-That 'case4 no task for the unused guid' (-not (Get-ScheduledTask -TaskName "ClaudeKeepwarm-$unusedGuid" -ErrorAction SilentlyContinue))

} finally {
    $env:PATH = $originalPath
    if ($stubDir) { Remove-Item -LiteralPath $stubDir -Recurse -Force -ErrorAction SilentlyContinue }
    if ($session) {
        # Only ever this session's own task — never a foreign one.
        Unregister-ScheduledTask -TaskName "ClaudeKeepwarm-$($session.SessionId)" -Confirm:$false -ErrorAction SilentlyContinue
        foreach ($f in @(
                (Join-Path $env:TEMP "claude-keepwarm-$($session.SessionId).state.json"),
                (Join-Path $env:TEMP "claude-keepwarm-$($session.SessionId).log"),
                (Join-Path $env:TEMP "claude-keepwarm-probe-$($session.SessionId).log"))) {
            Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
        }
        Remove-ThrowawaySession -Session $session
    }
}

''
# Ground rule 2 — the foreign set must be exactly what it was.
$foreignTasksAfter = @(Get-ScheduledTask -TaskName 'ClaudeKeepwarm-*' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty TaskName | Sort-Object)
Assert-That 'foreign scheduled tasks unchanged' (($foreignTasksBefore -join '|') -eq ($foreignTasksAfter -join '|')) "after: $(if ($foreignTasksAfter) { $foreignTasksAfter -join ', ' } else { '(none)' })"

''
"Total spend this run: `$$([math]::Round($spent, 4)) (cap `$$MaxSpendUsd)"
"PASS=$pass FAIL=$fail"
if ($fail -gt 0) { exit 1 }
exit 0
