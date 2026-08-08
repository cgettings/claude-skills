<#
.SYNOPSIS
    Proves Ping-ClaudeSession.ps1 takes the right branch for every
    cache_miss_reason, without sending a ping.

.DESCRIPTION
    A collapsed cache read has two causes with opposite correct responses, and
    the script tells them apart by the reason the API recorded. This exercises
    the real script end to end — its gates, its state file, its log lines — by
    putting a shim `claude` on PATH that prints canned result JSON, and writing
    a transcript record for the classifier to find.

    Nothing here calls the API, so it costs nothing and needs no credentials.
    That is the point: a real system_changed cannot be summoned on demand, so
    the only way to exercise this branch repeatably is to fabricate its inputs.

.PARAMETER KeepArtifacts
    Leave the generated log, state file and transcript in place for inspection.

.EXAMPLE
    & .\Test-MissClassification.ps1

.OUTPUTS
    One line per case, then a PASS/FAIL total. Exits 1 on any failure.
#>
[CmdletBinding()]
param([switch]$KeepArtifacts)

$ErrorActionPreference = 'Stop'

$scripts = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts'
$ping = Join-Path $scripts 'Ping-ClaudeSession.ps1'
$work = Join-Path ([System.IO.Path]::GetTempPath()) "keepwarm-tests-$PID"

# A fixed id keeps the fabricated transcript out of the way of real sessions.
$sessionId = '11111111-1111-1111-1111-111111111111'
$projectDir = Join-Path $work 'fakeproj'
$shimDir = Join-Path $work 'shim'
New-Item -ItemType Directory -Force -Path $projectDir, $shimDir | Out-Null

# The shim prints whatever the current case wrote to CLAUDE_FAKE_JSON. A .cmd
# reading a file avoids quoting JSON through the shell.
Set-Content -LiteralPath (Join-Path $shimDir 'claude.cmd') -Encoding ascii -Value @(
    '@echo off'
    'type "%CLAUDE_FAKE_JSON%"'
)

# Resolve-ClaudeSessionContext looks the transcript up by mangled cwd, so the
# fabricated one has to live where it would really be.
$mangled = ((Resolve-Path -LiteralPath $projectDir).Path -replace '[:\\/]', '-')
$transcriptDir = Join-Path $env:USERPROFILE ".claude\projects\$mangled"
New-Item -ItemType Directory -Force -Path $transcriptDir | Out-Null
$transcript = Join-Path $transcriptDir "$sessionId.jsonl"

$originalPath = $env:PATH
$env:PATH = "$shimDir;$originalPath"

# Read and write counts are only required to trip the step 8b heuristic against
# the baseline below; the reason is what decides the branch.
$cases = @(
    @{ Name = 'system_changed';             Reason = 'system_changed';             Read = 0;     Write = 58782; Expect = 'RESET' }
    @{ Name = 'tools_changed';              Reason = 'tools_changed';              Read = 1200;  Write = 61646; Expect = 'RESET' }
    @{ Name = 'previous_message_not_found'; Reason = 'previous_message_not_found'; Read = 0;     Write = 33754; Expect = 'MISS'  }
    @{ Name = 'messages_changed';           Reason = 'messages_changed';           Read = 500;   Write = 40000; Expect = 'MISS'  }
    @{ Name = 'model_changed';              Reason = 'model_changed';              Read = 0;     Write = 45000; Expect = 'MISS'  }
    @{ Name = 'unavailable';                Reason = 'unavailable';                Read = 100;   Write = 50000; Expect = 'MISS'  }
    @{ Name = 'reason absent';              Reason = $null;                        Read = 0;     Write = 39062; Expect = 'MISS'  }
    @{ Name = 'healthy read';               Reason = $null;                        Read = 39062; Write = 26;    Expect = 'OK'    }
)

$baseline = 39062
$pass = 0
$fail = 0
$total = 0

try {
    foreach ($case in $cases) {
        $logPath = Join-Path $work 'ping.log'
        $statePath = Join-Path $work 'ping.state.json'
        Remove-Item -LiteralPath $logPath, $statePath -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            SessionId = $sessionId; MaxRead = $baseline; PingCount = 3; FirstPing = '2026-08-08 00:00:00'
        } | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8

        # Canned CLI result. Note it carries usage but no diagnostics — the real
        # shape, and the reason the transcript has to be consulted at all.
        $fakePath = Join-Path $work 'fake.json'
        @{
            type = 'result'; subtype = 'success'; is_error = $false; total_cost_usd = 0.02
            usage = @{ cache_read_input_tokens = $case.Read; cache_creation_input_tokens = $case.Write }
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $fakePath -Encoding ascii
        $env:CLAUDE_FAKE_JSON = $fakePath

        $message = @{
            role = 'assistant'
            usage = @{ cache_read_input_tokens = $case.Read; cache_creation_input_tokens = $case.Write }
        }
        if ($case.Reason) { $message.diagnostics = @{ cache_miss_reason = @{ type = $case.Reason } } }
        @{ type = 'assistant'; entrypoint = 'claude-vscode'; effort = 'low'; message = $message } |
            ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath $transcript -Encoding utf8

        # No -TaskName: the branch is judged by Status and state, and the test
        # must never register or unregister a real scheduled task.
        $result = & $ping -SessionId $sessionId -ProjectDir $projectDir -LogPath $logPath -StatePath $statePath
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json

        $ok = $result.Status -eq $case.Expect
        # A RESET must re-baseline to this ping's write. Leaving the old mark
        # would make the next healthy ping against the new prefix look diverged.
        if ($case.Expect -eq 'RESET' -and [int]$state.MaxRead -ne $case.Write) { $ok = $false }
        # Everything else must leave the mark alone.
        if ($case.Expect -ne 'RESET' -and [int]$state.MaxRead -ne $baseline) { $ok = $false }

        if ($ok) { $pass++ } else { $fail++ }
        $total++
        '{0,-28} expect={1,-5} got={2,-5} MaxRead={3,-6} {4}' -f
            $case.Name, $case.Expect, $result.Status, $state.MaxRead, $(if ($ok) { 'ok' } else { 'FAIL' })
        if (-not $ok) { "    log: $((Get-Content -LiteralPath $logPath -ErrorAction SilentlyContinue) -join '')" }
    }
    # --- Reset budget -------------------------------------------------------
    # Single-shot cases cannot see this failure: continuing through a rewrite is
    # correct once and ruinous without limit, because every rewrite is billed at
    # full prefix rate. Only a sequence shows the cap working, and only a
    # sequence shows an OK ping in the middle failing to refill it.
    ''
    'reset budget (MaxResets=3), one state file carried across pings:'

    $logPath = Join-Path $work 'budget.log'
    $statePath = Join-Path $work 'budget.state.json'
    Remove-Item -LiteralPath $logPath, $statePath -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        SessionId = $sessionId; MaxRead = $baseline; PingCount = 1; ResetCount = 0; FirstPing = '2026-08-08 00:00:00'
    } | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8

    # A healthy ping sits third so the run also proves the budget is a lifetime
    # total rather than a consecutive streak.
    $sequence = @(
        @{ Name = 'rewrite 1';       Reason = 'system_changed'; Read = 0;     Write = 50001; Expect = 'RESET'; Used = 1 }
        @{ Name = 'rewrite 2';       Reason = 'tools_changed';  Read = 0;     Write = 50002; Expect = 'RESET'; Used = 2 }
        @{ Name = 'healthy between'; Reason = $null;            Read = 50002; Write = 26;    Expect = 'OK';    Used = 2 }
        @{ Name = 'rewrite 3';       Reason = 'system_changed'; Read = 0;     Write = 50003; Expect = 'RESET'; Used = 3 }
        @{ Name = 'rewrite 4 (over)'; Reason = 'system_changed'; Read = 0;    Write = 50004; Expect = 'MISS';  Used = 3 }
    )

    foreach ($step in $sequence) {
        $fakePath = Join-Path $work 'fake.json'
        @{
            type = 'result'; subtype = 'success'; is_error = $false; total_cost_usd = 0.39
            usage = @{ cache_read_input_tokens = $step.Read; cache_creation_input_tokens = $step.Write }
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $fakePath -Encoding ascii
        $env:CLAUDE_FAKE_JSON = $fakePath

        $message = @{
            role = 'assistant'
            usage = @{ cache_read_input_tokens = $step.Read; cache_creation_input_tokens = $step.Write }
        }
        if ($step.Reason) { $message.diagnostics = @{ cache_miss_reason = @{ type = $step.Reason } } }
        @{ type = 'assistant'; entrypoint = 'claude-vscode'; effort = 'low'; message = $message } |
            ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath $transcript -Encoding utf8

        $result = & $ping -SessionId $sessionId -ProjectDir $projectDir -LogPath $logPath -StatePath $statePath
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json

        $ok = ($result.Status -eq $step.Expect) -and ([int]$state.ResetCount -eq $step.Used)
        if ($ok) { $pass++ } else { $fail++ }
        $total++
        '{0,-28} expect={1,-5} got={2,-5} ResetCount={3} (want {4}) {5}' -f
            $step.Name, $step.Expect, $result.Status, $state.ResetCount, $step.Used, $(if ($ok) { 'ok' } else { 'FAIL' })
    }

    # The over-budget stop must say why. A line reading "lineage diverged" would
    # send the next reader hunting for a lineage change that never happened.
    $lastLine = @(Get-Content -LiteralPath $logPath)[-1]
    $explains = $lastLine -match 'reset budget exhausted'
    $total++
    if ($explains) { $pass++ } else { $fail++ }
    '{0,-28} {1}' -f 'over-budget line explains why', $(if ($explains) { 'ok' } else { "FAIL: $lastLine" })
} finally {
    $env:PATH = $originalPath
    Remove-Item Env:CLAUDE_FAKE_JSON -ErrorAction SilentlyContinue
    if (-not $KeepArtifacts) {
        Remove-Item -LiteralPath $transcriptDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

''
"PASS=$pass FAIL=$fail of $total"
if ($fail -gt 0) { exit 1 }
exit 0
