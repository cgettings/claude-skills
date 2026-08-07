<#
.SYNOPSIS
    Reports the state of Claude Code prompt-cache keepwarm tasks: schedule,
    ping history, cache behaviour, and accumulated cost.

.DESCRIPTION
    For each registered keepwarm task, reads the scheduled task's own state
    plus the ping log and high-water file that Ping-ClaudeSession.ps1
    maintains, and summarises them.

    The field to read first is Status. OK means the pings are landing on the
    session's cache lineage and the keepwarm is doing its job. MISS means a
    ping's cache read collapsed and the task unregistered itself — from that
    point the session was no longer being kept warm, and resuming it will pay
    a full-prefix rewrite. ERROR means pings are failing outright.

.PARAMETER SessionId
    Report on one session. Defaults to every registered keepwarm.

.PARAMETER Tail
    Number of recent log lines to include per task. Default 5; 0 omits them.

.EXAMPLE
    & .\Get-ClaudeKeepwarm.ps1

    Summarise every keepwarm on the machine.

.EXAMPLE
    & .\Get-ClaudeKeepwarm.ps1 -SessionId 'd6f79d29-...' -Tail 20

    Read one session's full recent ping history.

.OUTPUTS
    PSCustomObject per keepwarm.
#>
[CmdletBinding()]
param(
    [string]$SessionId,
    [ValidateRange(0, 500)][int]$Tail = 5
)

$ErrorActionPreference = 'Stop'

# STEP 1 — collect the sessions to report on, from two sources.
# One session if asked for, otherwise every registered keepwarm.
$filter = if ($SessionId) { "ClaudeKeepwarm-$SessionId" } else { 'ClaudeKeepwarm-*' }
$tasks = @(Get-ScheduledTask -TaskName $filter -ErrorAction SilentlyContinue)

# A finished keepwarm deletes its task but leaves the log behind, and that log
# is the only record of whether the night worked. Report those too.
$logFiles = @(Get-ChildItem -LiteralPath $env:TEMP -Filter 'claude-keepwarm-*.log' -File -ErrorAction SilentlyContinue)

# Merge both sources into one de-duplicated list of session ids: tasks first,
# then any log whose task is already gone.
$sessionIds = [System.Collections.Generic.List[string]]::new()
foreach ($task in $tasks) { $sessionIds.Add(($task.TaskName -replace '^ClaudeKeepwarm-', '')) }
foreach ($log in $logFiles) {
    $id = $log.BaseName -replace '^claude-keepwarm-', ''
    if ($SessionId -and $id -ne $SessionId) { continue }
    if (-not $sessionIds.Contains($id)) { $sessionIds.Add($id) }
}

if ($sessionIds.Count -eq 0) {
    Write-Verbose 'No keepwarm tasks are registered and no keepwarm logs were found.'
    return
}

# STEP 2 — build one summary object per session.
foreach ($id in $sessionIds) {
    $taskName = "ClaudeKeepwarm-$id"
    $task = $tasks | Where-Object { $_.TaskName -eq $taskName } | Select-Object -First 1
    $logPath = Join-Path $env:TEMP "claude-keepwarm-$id.log"
    $statePath = Join-Path $env:TEMP "claude-keepwarm-$id.state.json"

    $lines = @()
    if (Test-Path -LiteralPath $logPath) {
        $lines = @(Get-Content -LiteralPath $logPath -ErrorAction SilentlyContinue)
    }

    # Tally the log by outcome. Each ping wrote exactly one line tagged with its
    # status, so counting the tags reconstructs the night.
    $okCount = @($lines | Where-Object { $_ -match '\sOK\s' }).Count
    $missCount = @($lines | Where-Object { $_ -match '\sMISS\s' }).Count
    $errorCount = @($lines | Where-Object { $_ -match '\sERROR\s' }).Count

    # Sum the per-ping costs the log recorded, so the night has a running total.
    $totalCost = 0.0
    foreach ($line in $lines) {
        if ($line -match 'cost=\$([0-9.]+)') { $totalCost += [double]$Matches[1] }
    }

    # Worst outcome seen wins: a night that ended in a MISS was not a success,
    # however many OK lines came before it.
    $status = if ($missCount -gt 0) { 'MISS' }
        elseif ($lines.Count -eq 0) { 'NoPingsYet' }
        elseif ($errorCount -gt 0 -and $okCount -eq 0) { 'ERROR' }
        elseif ($errorCount -gt 0) { 'OK (with errors)' }
        else { 'OK' }

    # The high-water mark, when the state file survives.
    $state = $null
    if (Test-Path -LiteralPath $statePath) {
        try { $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -ErrorAction Stop } catch { }
    }

    # Schedule timings live on the task, which is absent once it has expired.
    $info = if ($task) { $task | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue } else { $null }

    [PSCustomObject]@{
        SessionId        = $id
        Status           = $status
        TaskRegistered   = [bool]$task
        TaskState        = if ($task) { [string]$task.State } else { 'Unregistered' }
        NextRunTime      = if ($info) { $info.NextRunTime } else { $null }
        LastRunTime      = if ($info) { $info.LastRunTime } else { $null }
        Pings            = $lines.Count
        OkPings          = $okCount
        MissPings        = $missCount
        ErrorPings       = $errorCount
        CacheHighWater   = if ($state) { $state.MaxRead } else { $null }
        TotalCostUsd     = [math]::Round($totalCost, 4)
        LogPath          = $logPath
        RecentLog        = if ($Tail -gt 0) { $lines | Select-Object -Last $Tail } else { $null }
    }
}
