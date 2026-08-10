<#
.SYNOPSIS
    Proves the MISS branch, deciding unattended, takes down a real Windows
    Scheduled Task. THIS ONE SPENDS MONEY and registers a real scheduled task.

.DESCRIPTION
    tests/README.md says the miss branch has never been observed deciding
    unattended on a real task. This script is that observation — with one
    honest limit stated up front.

    HOW THE MISS IS TRIGGERED, AND WHAT THAT DOES AND DOESN'T PROVE.
    A divergence cannot be forced on a `claude -p` throwaway: neither
    CLAUDE_CODE_ENTRYPOINT nor --effort moves the prefix such a session renders
    (measured across three throwaways 2026-08-09 — see
    PLAN-live-test-coverage.md). So the collapse is manufactured from the other
    side of the comparison. Ping-ClaudeSession.ps1:285 declares divergence when
    `read < MaxRead * ReadDropThreshold` AND `write > MinWriteTokens`; this
    script seeds an inflated MaxRead into the state file and passes
    -MinWriteTokens 10, so a perfectly healthy ping satisfies both halves.

    What that proves is everything downstream of the decision, which is the
    part that has never run for real: the branch is entered, the reason lookup
    happens against a real transcript, Unregister-ScheduledTask is called on a
    real registered task, the task is actually gone, and the log line says so.
    What it does NOT prove is the detection itself — the numbers that entered
    the comparison are healthy ones. The offline suite covers the arithmetic;
    this covers the consequence.

    Case 2 reports the one genuinely real cache miss this harness can observe:
    the first --resume after a `claude -p` create, which reports
    cache_miss_reason=system_changed with a multi-thousand-token write.
    New-ThrowawaySession.ps1 captures it; nothing here has to buy it twice.

    Ground rule 2: foreign ClaudeKeepwarm-* tasks are snapshotted before
    anything registers and re-checked at the end. Only this session's own task
    is ever unregistered.

.PARAMETER MaxSpendUsd
    Aborts before any step that would push cumulative cost past this.

.EXAMPLE
    & .\Test-LiveMissAbort.ps1

.OUTPUTS
    One line per assertion plus the observed cache_miss_reason values, then a
    PASS/FAIL total. Exits 1 on any failure.
#>
[CmdletBinding()]
param(
    [double]$MaxSpendUsd = 1.00
)

$ErrorActionPreference = 'Stop'

$testsDir = $PSScriptRoot
$scriptsDir = Join-Path (Split-Path -Parent $testsDir) 'scripts'
$startScript = Join-Path $scriptsDir 'Start-ClaudeKeepwarm.ps1'
$pingScript = Join-Path $scriptsDir 'Ping-ClaudeSession.ps1'
. (Join-Path $testsDir 'New-ThrowawaySession.ps1')
. (Join-Path $scriptsDir 'Get-CacheMissReason.ps1')

$spent = 0.0
$pass = 0
$fail = 0
$session = $null

function Assert-That {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) { $script:pass++ } else { $script:fail++ }
    '{0,-52} {1} {2}' -f $Name, $(if ($Condition) { 'ok' } else { 'FAIL' }), $Detail
}

$foreignTasksBefore = @(Get-ScheduledTask -TaskName 'ClaudeKeepwarm-*' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty TaskName | Sort-Object)
"Foreign ClaudeKeepwarm-* tasks before: $(if ($foreignTasksBefore) { $foreignTasksBefore -join ', ' } else { '(none)' })"

try {
    $session = New-ThrowawaySession -MaxSpendUsd $MaxSpendUsd
    $spent += $session.CostUsd
    $taskName = "ClaudeKeepwarm-$($session.SessionId)"
    "Throwaway: $($session.SessionId) createCost=`$$($session.CostUsd)"
    ''

    # --- Case 1: register a real task, then make one ping decide to kill it.
    '--- case 1: the MISS branch takes down a real scheduled task'
    $started = & $startScript -SessionId $session.SessionId -ProjectDir $session.ProjectDir `
        -Entrypoint $session.Entrypoint -Effort $session.Effort -IntervalMinutes 1 -DurationHours 0.1
    $spent += [double]$started.ProbeCostUsd
    Assert-That 'case1 task registered' ([bool](Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) $taskName

    # Seed the high-water mark far above anything a healthy ping can read, so
    # the read-collapse half of the test at Ping-ClaudeSession.ps1:285 holds.
    $seededMaxRead = [int]$started.ProbeRead * 4
    [PSCustomObject]@{
        SessionId  = $session.SessionId
        MaxRead    = $seededMaxRead
        PingCount  = 1
        ResetCount = 0
        FirstPing  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    } | ConvertTo-Json | Set-Content -LiteralPath $started.StatePath -Encoding utf8
    "seeded MaxRead=$seededMaxRead into $($started.StatePath)"

    if ($spent -gt $MaxSpendUsd) { throw "Spend cap exceeded before the ping: `$$([math]::Round($spent, 4)) > `$$MaxSpendUsd" }

    # -MinWriteTokens 10 so a healthy ping's small write satisfies the second
    # half. This is the whole manufactured part; everything after is real.
    $ping = & $pingScript -SessionId $session.SessionId -ProjectDir $session.ProjectDir `
        -LogPath $started.LogPath -StatePath $started.StatePath -TaskName $taskName `
        -Entrypoint $session.Entrypoint -Effort $session.Effort -MinWriteTokens 10
    $spent += [double]$ping.CostUsd

    Assert-That 'case1 ping Status is MISS' ($ping.Status -eq 'MISS') "Status=$($ping.Status) read=$($ping.CacheRead) write=$($ping.CacheWrite)"
    Assert-That 'case1 scheduled task no longer exists' (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue))

    $lastLine = (Get-Content -LiteralPath $started.LogPath -Tail 1)
    "log: $lastLine"
    Assert-That 'case1 last log line is tagged MISS' ($lastLine -match '\sMISS\s')
    Assert-That 'case1 log records the unregister' ($lastLine -like "*unregistered '$taskName'*")
    Assert-That 'case1 log has no FAILED to unregister' ($lastLine -notlike '*FAILED to unregister*')
    ''

    # --- Case 2: report the real cache_miss_reason values this run saw.
    '--- case 2: observed cache_miss_reason values (reported, not asserted)'
    $pingReason = Get-CacheMissReason -Read $ping.CacheRead -Write $ping.CacheWrite -TranscriptPath $session.TranscriptPath
    "first --resume after create: read=$($session.FirstResumeRead) write=$($session.FirstResumeWrite) reason=$(if ($session.FirstResumeReason) { $session.FirstResumeReason } else { '(none)' })"
    "the MISS ping itself:        read=$($ping.CacheRead) write=$($ping.CacheWrite) reason=$(if ($pingReason) { $pingReason } else { '(none)' })"
    Assert-That 'case2 first resume reported a real miss reason' ([bool]$session.FirstResumeReason) "reason=$($session.FirstResumeReason)"
    # The MISS ping was a healthy cache read, so it must have no reason at all.
    # That is what routed it past the RESET branch into MISS, and asserting it
    # keeps the manufactured trigger honest about what it manufactured.
    Assert-That 'case2 MISS ping itself had no miss reason' (-not $pingReason) "reason=$(if ($pingReason) { $pingReason } else { '(none)' })"

} finally {
    if ($session) {
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
$foreignTasksAfter = @(Get-ScheduledTask -TaskName 'ClaudeKeepwarm-*' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty TaskName | Sort-Object)
Assert-That 'foreign scheduled tasks unchanged' (($foreignTasksBefore -join '|') -eq ($foreignTasksAfter -join '|')) "after: $(if ($foreignTasksAfter) { $foreignTasksAfter -join ', ' } else { '(none)' })"

''
"Total spend this run: `$$([math]::Round($spent, 4)) (cap `$$MaxSpendUsd)"
"PASS=$pass FAIL=$fail"
if ($fail -gt 0) { exit 1 }
exit 0
