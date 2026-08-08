<#
.SYNOPSIS
    Checks Get-ClaudeKeepwarm.ps1 counts each ping tag correctly, and that a
    RESET is not reported as a failed night.

.DESCRIPTION
    The tally is regex over log lines, which makes one thing worth asserting
    directly rather than by eye: RESET must not be swept up by the MISS
    counter. It is not, because the MISS pattern requires whitespace on both
    sides — but that is a property of a regex someone could reasonably tighten
    or loosen later, so it gets a test.

    Writes one synthetic log into $env:TEMP under a reserved session id and
    removes it afterwards. No API calls.

.EXAMPLE
    & .\Test-StatusTally.ps1

.OUTPUTS
    The tallied object, then a PASS/FAIL total. Exits 1 on any failure.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$status = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\Get-ClaudeKeepwarm.ps1'
$sessionId = '22222222-2222-2222-2222-222222222222'
$logPath = Join-Path $env:TEMP "claude-keepwarm-$sessionId.log"

# One line per tag the ping script emits, in the format it emits them.
@(
    '2026-08-08 00:00:00 BASE  read=39062 write=26 cost=$0.02 (baseline established)'
    '2026-08-08 00:55:00 OK    read=39100 write=26 cost=$0.02'
    '2026-08-08 01:50:00 RESET read=0 write=58782 cost=$0.39  prefix rewritten (system_changed): read fell 100% below high-water 39100; re-baselined and continuing'
    '2026-08-08 02:45:00 OK    read=58800 write=26 cost=$0.02'
) | Set-Content -LiteralPath $logPath -Encoding utf8

try {
    $report = & $status -SessionId $sessionId -Tail 0
    $report | Select-Object Status, Pings, OkPings, ResetPings, MissPings, ErrorPings, TotalCostUsd | Format-List | Out-String | Write-Output

    $checks = [ordered]@{
        "Status is 'OK (with resets)'" = $report.Status -eq 'OK (with resets)'
        'ResetPings = 1'               = $report.ResetPings -eq 1
        'RESET not counted as MISS'    = $report.MissPings -eq 0
        'OkPings = 2'                  = $report.OkPings -eq 2
        'ErrorPings = 0'               = $report.ErrorPings -eq 0
        'TotalCostUsd = 0.45'          = [math]::Abs($report.TotalCostUsd - 0.45) -lt 0.0001
    }

    $pass = 0
    $fail = 0
    foreach ($name in $checks.Keys) {
        if ($checks[$name]) { $pass++ } else { $fail++ }
        '{0,-30} {1}' -f $name, $(if ($checks[$name]) { 'ok' } else { 'FAIL' })
    }
} finally {
    Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
}

''
"PASS=$pass FAIL=$fail of $($checks.Count)"
if ($fail -gt 0) { exit 1 }
exit 0
