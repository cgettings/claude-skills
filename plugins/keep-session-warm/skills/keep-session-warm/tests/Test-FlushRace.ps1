<#
.SYNOPSIS
    Measures how long after `claude -p --resume` returns the ping's own
    transcript record becomes readable. THIS ONE SPENDS MONEY.

.DESCRIPTION
    Get-CacheMissReason reads the reason out of the transcript after the ping
    has already returned, so it races the harness's own flush. Every other test
    here fabricates its records and therefore cannot see that race at all —
    this is the only one that can, and it needs a real API call to do it.

    Measured 2026-08-08 on a warm session: readable after 44 ms against a
    500 ms default, with the process having exited 70 ms earlier. Re-run it
    after any change to how the ping is invoked.

    Cost: one resume ping. Against a session whose cache is still warm that was
    $0.020 (read=39062 write=26); against a cold one it is a full-prefix write,
    roughly $0.39 on a small session and far more on a large one. Use a
    throwaway session, and use one you pinged recently.

    Pin -Entrypoint and -Effort to whatever the target session runs under, or
    the ping lands on a different cache lineage and pays for a rewrite.

.PARAMETER SessionId
    A throwaway session to ping. Required — there is no safe default.

.PARAMETER ProjectDir
    The directory that session was created in.

.PARAMETER Entrypoint
    CLAUDE_CODE_ENTRYPOINT the session runs under, e.g. claude-vscode.

.PARAMETER Effort
    Effort level the session runs at.

.PARAMETER BudgetMs
    How long to keep looking before declaring the default timeout too short.

.EXAMPLE
    & .\Test-FlushRace.ps1 -SessionId '8e0e6024-...' -ProjectDir 'C:\tmp\scratch' -Entrypoint claude-vscode -Effort medium

.OUTPUTS
    The ping's cache numbers, the flush latency, and a PASS/FAIL. Exits 1 if
    the record never appeared.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SessionId,
    [Parameter(Mandatory)][string]$ProjectDir,
    [string]$Entrypoint,
    [ValidateSet('low', 'medium', 'high', 'xhigh', 'max')][string]$Effort,
    [int]$BudgetMs = 5000
)

$ErrorActionPreference = 'Stop'

$scripts = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts'
. (Join-Path $scripts 'Get-CacheMissReason.ps1')
. (Join-Path $scripts 'Resolve-ClaudeSessionContext.ps1')

$transcript = (Resolve-ClaudeSessionContext -SessionId $SessionId -ProjectDir $ProjectDir).TranscriptPath

Set-Location -LiteralPath $ProjectDir
if ($Entrypoint) { $env:CLAUDE_CODE_ENTRYPOINT = $Entrypoint }
else { Remove-Item Env:CLAUDE_CODE_ENTRYPOINT -ErrorAction SilentlyContinue }

$claudeArgs = @('-p', '--resume', $SessionId, 'Acknowledge and take no action.', '--output-format', 'json')
if ($Effort) { $claudeArgs += @('--effort', $Effort) }

$json = & claude @claudeArgs
$exited = [datetime]::UtcNow
$result = $json | ConvertFrom-Json
if ($result.is_error -or $result.subtype -ne 'success') {
    "ping failed: subtype=$($result.subtype) $($result.result)"
    exit 1
}

$read = [int]$result.usage.cache_read_input_tokens
$write = [int]$result.usage.cache_creation_input_tokens
"ping returned: read=$read write=$write cost=`$$([math]::Round($result.total_cost_usd, 4))"

# Poll for the ping's own record, identified the way the function identifies it.
$found = $false
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
while ($stopwatch.ElapsedMilliseconds -lt $BudgetMs -and -not $found) {
    foreach ($line in @(Get-Content -LiteralPath $transcript -Tail 50 -ErrorAction SilentlyContinue)) {
        try { $record = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
        if ($record.type -ne 'assistant') { continue }
        if ([int]$record.message.usage.cache_read_input_tokens -eq $read -and
            [int]$record.message.usage.cache_creation_input_tokens -eq $write) { $found = $true; break }
    }
    if (-not $found) { Start-Sleep -Milliseconds 10 }
}
$stopwatch.Stop()

if (-not $found) {
    "record NOT readable within ${BudgetMs}ms - the 500ms default is too short"
    "PASS=0 FAIL=1"
    exit 1
}

"record readable after $($stopwatch.ElapsedMilliseconds)ms (Get-CacheMissReason default timeout is 500ms)"
"wall time since claude exited: $([math]::Round(([datetime]::UtcNow - $exited).TotalMilliseconds))ms"

# And the real function, at its real default, on the record just written.
$reason = Get-CacheMissReason -Read $read -Write $write -SessionId $SessionId -ProjectDir $ProjectDir
"Get-CacheMissReason returned: $(if ($null -eq $reason) { '<null>' } else { $reason })"
if ($null -eq $reason) {
    '  (null is expected for a healthy ping - a cache hit carries no cache_miss_reason)'
} else {
    "  (this ping actually missed - see SKILL.md section 4 for what $reason means)"
}

''
"PASS=1 FAIL=0"
exit 0
