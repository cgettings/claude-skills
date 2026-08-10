<#
.SYNOPSIS
    Measures what Test-ClaudeCacheLineage.ps1 reports on a matching invocation
    and on a mismatched one. THIS ONE SPENDS MONEY.

.DESCRIPTION
    This was written to buy the rewrite the offline suite refuses to buy —
    tests/README.md's "What none of them prove" section says the Diverged
    branch has never been observed against a real measurement. It still hasn't
    been, and this script is now the record of why.

    Case 2 varies CLAUDE_CODE_ENTRYPOINT and measured no divergence at all:
    read fraction 1.00, same as the matching probe (2026-08-09, CLI 2.1.220).
    Varying --effort behaves identically. So this suite establishes a null —
    neither lineage key moves the prefix a `claude -p --resume` renders — and
    case 2 asserts that null so a future CLI change would break it loudly.
    What it does NOT establish is that entrypoint is inert on an *interactive*
    session, which is where SKILL.md's divergence was measured; these
    throwaways are created by `claude -p`.

    Runs three cases against one throwaway session, in this exact order (see
    the plan's Ordering hazard): a matching-lineage probe, a mismatched one,
    then a repeat of the matching probe to confirm the session still re-warms.

    Also asserts, after every case, that the probe left no state file behind —
    Test-ClaudeCacheLineage.ps1 passes no -StatePath and must never establish
    a high-water mark a later real keepwarm would inherit.

.PARAMETER MaxSpendUsd
    Aborts the moment cumulative cost (throwaway creation + all three probes)
    would exceed this.

.EXAMPLE
    & .\Test-LiveLineageVerdicts.ps1

.OUTPUTS
    One row per case with CacheRead/CacheWrite/ReadFraction/CostUsd, then a
    PASS/FAIL total. Exits 1 on any failure.
#>
[CmdletBinding()]
param(
    [double]$MaxSpendUsd = 1.00
)

$ErrorActionPreference = 'Stop'

$testsDir = $PSScriptRoot
$scriptsDir = Join-Path (Split-Path -Parent $testsDir) 'scripts'
$lineageProbe = Join-Path $scriptsDir 'Test-ClaudeCacheLineage.ps1'
. (Join-Path $testsDir 'New-ThrowawaySession.ps1')

$spent = 0.0
$pass = 0
$fail = 0
$rows = @()
$session = $null

try {
    $session = New-ThrowawaySession -MaxSpendUsd $MaxSpendUsd
    $spent += $session.CostUsd
    "Throwaway: $($session.SessionId) model=$($session.Model) ModelPinHolds=$($session.ModelPinHolds) createCost=`$$($session.CostUsd)"

    function Invoke-Case {
        param([string]$Name, [string]$Entrypoint, [scriptblock]$Assert)
        if ($script:spent -gt $MaxSpendUsd) {
            throw "Spend cap exceeded before case '$Name': `$$([math]::Round($script:spent, 4)) > `$$MaxSpendUsd"
        }

        # -Effort is passed on every case, never resolved. A throwaway's
        # transcript carries no effort field, so Test-ClaudeCacheLineage.ps1's
        # own resolution path throws on it — see New-ThrowawaySession.ps1
        # STEP 3 and Test-LiveContextResolution.ps1, which tests that directly.
        $probeArgs = @{
            SessionId  = $session.SessionId
            ProjectDir = $session.ProjectDir
            Entrypoint = $Entrypoint
            Effort     = $session.Effort
        }
        $result = & $lineageProbe @probeArgs
        $script:spent += [double]$result.CostUsd

        $ok = & $Assert $result
        $script:pass += [int]$ok
        $script:fail += [int](-not $ok)

        # State-file assertion, every case: the probe must never leave a
        # high-water mark a later keepwarm would inherit.
        $statePath = Join-Path $env:TEMP "claude-keepwarm-$($session.SessionId).state.json"
        $stateAbsent = -not (Test-Path -LiteralPath $statePath)
        $script:pass += [int]$stateAbsent
        $script:fail += [int](-not $stateAbsent)

        $row = [PSCustomObject]@{
            Case         = $Name
            Verdict      = $result.Verdict
            CacheRead    = $result.CacheRead
            CacheWrite   = $result.CacheWrite
            ReadFraction = $result.ReadFraction
            CostUsd      = $result.CostUsd
            StateAbsent  = $stateAbsent
            Pass         = ($ok -and $stateAbsent)
        }
        $script:rows += $row
        '{0,-28} verdict={1,-16} read={2,-6} write={3,-6} readFrac={4,-7} cost=${5,-8} state-absent={6} {7}' -f
            $Name, $result.Verdict, $result.CacheRead, $result.CacheWrite, $result.ReadFraction, $result.CostUsd,
            $stateAbsent, $(if ($row.Pass) { 'ok' } else { 'FAIL' })
        return $result
    }

    # Case 1 — matching lineage (must run before any divergence case; see the
    # plan's Ordering hazard).
    Invoke-Case -Name 'case1: matching lineage' -Entrypoint $session.Entrypoint -Assert {
        param($r)
        ($r.Verdict -in @('Warm', 'WarmWithBacklog')) -and ($r.ReadFraction -ge 0.5)
    } | Out-Null

    # Case 2 — a mismatched entrypoint. This case asserts the NULL, on purpose.
    #
    # It was written expecting Diverged, and measured Warm at read fraction 1.00
    # (2026-08-09). Varying --effort, and varying both keys at once, also gave
    # 1.00 — see PLAN-live-test-coverage.md's ledger for the five-probe table
    # and its positive control. Neither lineage key moves the prefix that
    # `claude -p --resume` renders, so a divergence cannot be forced this way
    # and this suite cannot produce a Diverged verdict.
    #
    # The assertion is inverted rather than deleted so the null keeps being
    # re-measured: if a future CLI makes entrypoint load-bearing again, this
    # case fails and says so, which is the whole reason it still costs a ping.
    Invoke-Case -Name 'case2: entrypoint mismatch is inert' -Entrypoint 'keepwarm-live-divergence-probe' -Assert {
        param($r)
        ($r.Verdict -in @('Warm', 'WarmWithBacklog')) -and ($r.ReadFraction -ge 0.9)
    } | Out-Null

    # Case 3 — re-run case 1 verbatim: the original lineage must survive the
    # excursion and re-warm.
    Invoke-Case -Name 'case3: re-warm original lineage' -Entrypoint $session.Entrypoint -Assert {
        param($r)
        $r.Verdict -in @('Warm', 'WarmWithBacklog')
    } | Out-Null

} finally {
    if ($session) {
        # The probe log matters: Get-ClaudeKeepwarm.ps1 globs
        # claude-keepwarm-*.log, so a stray probe log makes the user's own
        # status report list a phantom session named probe-<id>.
        Remove-Item -LiteralPath (Join-Path $env:TEMP "claude-keepwarm-probe-$($session.SessionId).log") -Force -ErrorAction SilentlyContinue
        Remove-ThrowawaySession -Session $session
    }
}

''
"Total spend this run: `$$([math]::Round($spent, 4)) (cap `$$MaxSpendUsd)"
''
"PASS=$pass FAIL=$fail"
$rows | Format-Table -AutoSize | Out-String | Write-Host
if ($fail -gt 0) { exit 1 }
exit 0
