<#
.SYNOPSIS
    Replays Get-CacheMissReason against real session transcripts and checks it
    returns the reason those transcripts actually recorded.

.DESCRIPTION
    Test-MissClassification.ps1 proves the branch is wired correctly using
    fabricated records. This proves the thing feeding it reads real ones — the
    two are separate failures and only this one has authentic input.

    Cases are drawn from whatever is under ~/.claude/projects on this machine,
    so coverage depends on what that holds. The run prints which reasons it
    found, and a reason with no cases is reported rather than silently passing:
    a replay that quietly tested nothing is exactly the null result this
    tooling is supposed to be suspicious of.

    Read-only, no API calls, no credentials.

.PARAMETER ProjectsRoot
    Where to look for transcripts. Defaults to ~/.claude/projects.

.PARAMETER MaxFiles
    Transcripts to scan. Bounded because every line is JSON-parsed.

.PARAMETER MaxFileBytes
    Skip transcripts larger than this, which are slow and add little.

.PARAMETER MaxCasesPerReason
    Cases to keep per distinct reason value.

.EXAMPLE
    & .\Test-ReasonReplay.ps1

.OUTPUTS
    Coverage per reason, an ambiguity count, then a PASS/FAIL total.
    Exits 1 on any failure.
#>
[CmdletBinding()]
param(
    [string]$ProjectsRoot = (Join-Path $env:USERPROFILE '.claude\projects'),
    [int]$MaxFiles = 60,
    [int]$MaxFileBytes = 3000000,
    [int]$MaxCasesPerReason = 10
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\Get-CacheMissReason.ps1')

if (-not (Test-Path -LiteralPath $ProjectsRoot)) {
    "No transcripts at '$ProjectsRoot' — nothing to replay."
    exit 1
}

$files = Get-ChildItem -LiteralPath $ProjectsRoot -Filter '*.jsonl' -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -le $MaxFileBytes } |
    Select-Object -First $MaxFiles

$byReason = @{}
$noReason = [System.Collections.Generic.List[object]]::new()
$ambiguous = 0

foreach ($file in $files) {
    # Last record wins per (read, write) key — the same rule the function uses
    # when scanning backwards. The ambiguity counter below is what establishes
    # that this rule is not quietly picking between conflicting answers.
    $lastByKey = @{}
    $seen = @{}
    foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
        if (-not $line.Contains('"assistant"')) { continue }
        try { $record = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
        if ($record.type -ne 'assistant') { continue }
        $usage = $record.message.usage
        if ($null -eq $usage) { continue }

        $key = '{0}|{1}' -f [int]$usage.cache_read_input_tokens, [int]$usage.cache_creation_input_tokens
        $reason = $record.message.diagnostics.cache_miss_reason.type
        if ($seen.ContainsKey($key) -and $seen[$key] -ne $reason) { $ambiguous++ }
        $seen[$key] = $reason
        $lastByKey[$key] = $reason
    }

    foreach ($key in $lastByKey.Keys) {
        $parts = $key -split '\|'
        $case = [PSCustomObject]@{
            File = $file.FullName; Read = [int]$parts[0]; Write = [int]$parts[1]; Expected = $lastByKey[$key]
        }
        if ($case.Expected) {
            if (-not $byReason.ContainsKey($case.Expected)) {
                $byReason[$case.Expected] = [System.Collections.Generic.List[object]]::new()
            }
            if ($byReason[$case.Expected].Count -lt $MaxCasesPerReason) { $byReason[$case.Expected].Add($case) }
        } elseif ($noReason.Count -lt $MaxCasesPerReason) {
            $noReason.Add($case)
        }
    }
}

$cases = [System.Collections.Generic.List[object]]::new()
foreach ($reason in $byReason.Keys) { $byReason[$reason] | ForEach-Object { $cases.Add($_) } }
$noReason | ForEach-Object { $cases.Add($_) }

'Scanned {0} transcripts under {1}' -f $files.Count, $ProjectsRoot
'Coverage: {0}' -f (($byReason.Keys | Sort-Object | ForEach-Object { "$_=$($byReason[$_].Count)" }) -join ' ')
'          no-reason={0}' -f $noReason.Count
'Ambiguous (read,write) keys mapping to conflicting reasons: {0}' -f $ambiguous
''

if ($cases.Count -eq 0) {
    'No cases found — the replay proved nothing. Treat this as a failure, not a pass.'
    exit 1
}

$pass = 0
$fail = 0
foreach ($case in $cases) {
    # TimeoutMs 0 because the record is already on disk; TailLines large because
    # historical records sit anywhere in the file, not just near the end.
    $got = Get-CacheMissReason -Read $case.Read -Write $case.Write -TranscriptPath $case.File `
        -TimeoutMs 0 -TailLines 200000
    if ($got -eq $case.Expected -or ($null -eq $got -and $null -eq $case.Expected)) {
        $pass++
    } else {
        $fail++
        "FAIL expected='{0}' got='{1}' read={2} write={3} {4}" -f
            $case.Expected, $got, $case.Read, $case.Write, (Split-Path $case.File -Leaf)
    }
}

"PASS=$pass FAIL=$fail of $($cases.Count)"
if ($fail -gt 0) { exit 1 }
exit 0
