<#
.SYNOPSIS
    Stops a Claude Code prompt-cache keepwarm started by
    Start-ClaudeKeepwarm.ps1.

.DESCRIPTION
    Unregisters the per-session scheduled task and removes its state file.
    Safe to call when the task already expired and self-deleted, or was never
    started — both report and exit cleanly rather than erroring.

    Run this before resuming a session interactively while its keepwarm is
    still active. The scheduled ping and the live session both resume and
    append to the same transcript file, and nothing coordinates those two
    writers.

.PARAMETER SessionId
    The session whose keepwarm to stop. Defaults to
    $env:CLAUDE_CODE_SESSION_ID, so calling this from inside the session you
    are about to keep working in just works.

.PARAMETER All
    Stop every registered Claude keepwarm rather than one session's. Useful
    when tasks were left behind by sessions you no longer have ids for.

.PARAMETER PassThru
    Return a PSCustomObject per task acted on.

.EXAMPLE
    & .\Stop-ClaudeKeepwarm.ps1

    Stop the current session's keepwarm before resuming work in it.

.EXAMPLE
    & .\Stop-ClaudeKeepwarm.ps1 -All -PassThru

    Clear every keepwarm task on the machine and report what was removed.

.OUTPUTS
    None by default; PSCustomObject per task with -PassThru.
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Session')]
param(
    [Parameter(ParameterSetName = 'Session')]
    [string]$SessionId = $env:CLAUDE_CODE_SESSION_ID,

    [Parameter(Mandatory, ParameterSetName = 'All')]
    [switch]$All,

    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'

# STEP 1 — decide which tasks to act on. Either every keepwarm, or the one
# belonging to a single session.
if ($All.IsPresent) {
    $tasks = @(Get-ScheduledTask -TaskName 'ClaudeKeepwarm-*' -ErrorAction SilentlyContinue)
    if (-not $tasks) {
        Write-Verbose 'No Claude keepwarm tasks are registered.'
        return
    }
} else {
    if (-not $SessionId) {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new('No -SessionId given and CLAUDE_CODE_SESSION_ID is not set. Pass -SessionId explicitly, or use -All.'),
                'SessionIdMissing', [System.Management.Automation.ErrorCategory]::InvalidArgument, $null))
    }

    # Must match the naming scheme Start-ClaudeKeepwarm.ps1 registers under.
    $taskName = "ClaudeKeepwarm-$SessionId"

    # Check first: an expired task self-deletes, and Unregister-ScheduledTask
    # errors on a name that no longer exists.
    $tasks = @(Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)
    if (-not $tasks) {
        Write-Verbose "'$taskName' was not running (already expired and self-deleted, or never started)."
        if ($PassThru.IsPresent) {
            [PSCustomObject]@{ TaskName = $taskName; SessionId = $SessionId; Action = 'NotFound' }
        }
        return
    }
}

# STEP 2 — unregister each one and clear its high-water mark, so a later
# keepwarm on the same session starts from a fresh baseline. The ping log is
# deliberately left in place: it is the record of whether the night worked.
foreach ($task in $tasks) {
    if (-not $PSCmdlet.ShouldProcess($task.TaskName, 'Unregister scheduled task')) { continue }

    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false

    $taskSessionId = $task.TaskName -replace '^ClaudeKeepwarm-', ''
    $statePath = Join-Path $env:TEMP "claude-keepwarm-$taskSessionId.state.json"
    Remove-Item -LiteralPath $statePath -Force -ErrorAction SilentlyContinue

    if ($PassThru.IsPresent) {
        [PSCustomObject]@{
            TaskName  = $task.TaskName
            SessionId = $taskSessionId
            Action    = 'Unregistered'
            LogPath   = Join-Path $env:TEMP "claude-keepwarm-$taskSessionId.log"
        }
    }
}
