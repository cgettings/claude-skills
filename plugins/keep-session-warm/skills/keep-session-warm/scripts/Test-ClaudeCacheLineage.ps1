<#
.SYNOPSIS
    Sends one probe ping to a Claude Code session and reports whether it landed
    on the session's prompt-cache lineage.

.DESCRIPTION
    Answers the question the keepwarm depends on and cannot assume: will a
    `claude -p --resume` invocation carrying these lineage keys be served as a
    cache read, or will it write a fresh prefix?

    The verdict comes from the split between cache read and cache write. A
    resume that lands on the session's lineage reads nearly the whole prefix
    and writes only the new turn. One that does not reads up to the point where
    the prompt prefixes diverge and rewrites everything after it — measured at
    12,424 read against 22,150 written on a session whose matching resume read
    37,950 and wrote 19.

    This costs one cache read plus a few output tokens, and appends one turn to
    the session's transcript. It deliberately does not probe the mismatching
    case: reproducing a divergence on a real session means paying for a
    full-prefix write, which on a long session is the single most expensive
    thing this tooling exists to avoid.

.PARAMETER SessionId
    The session to probe. Defaults to $env:CLAUDE_CODE_SESSION_ID.

.PARAMETER ProjectDir
    The directory the session was created in. Defaults to the current
    directory.

.PARAMETER Entrypoint
    Override the CLAUDE_CODE_ENTRYPOINT to probe with. Defaults to the value
    the session's most recent turn recorded — the same value
    Start-ClaudeKeepwarm.ps1 would pin.

.PARAMETER Effort
    Override the effort level to probe with. Defaults to the session's most
    recent turn.

.EXAMPLE
    & .\Test-ClaudeCacheLineage.ps1

    Probe the current session and report the verdict before trusting a
    schedule to it.

.OUTPUTS
    PSCustomObject with Verdict, CacheRead, CacheWrite, ReadFraction,
    PrefixTokens, CostUsd, and the lineage keys used.
#>
[CmdletBinding()]
param(
    [string]$SessionId = $env:CLAUDE_CODE_SESSION_ID,
    [string]$ProjectDir = (Get-Location).Path,
    [string]$Entrypoint,
    [ValidateSet('low', 'medium', 'high', 'xhigh', 'max')][string]$Effort
)

$ErrorActionPreference = 'Stop'

if (-not $SessionId) {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new('No -SessionId given and CLAUDE_CODE_SESSION_ID is not set. Pass -SessionId explicitly.'),
            'SessionIdMissing', [System.Management.Automation.ErrorCategory]::InvalidArgument, $null))
}

# STEP 1 — resolve the same lineage keys Start would pin, so the probe measures
# the configuration that would actually be scheduled.
$scriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDir 'Resolve-ClaudeSessionContext.ps1')

$context = Resolve-ClaudeSessionContext -SessionId $SessionId -ProjectDir $ProjectDir
if (-not $Entrypoint) { $Entrypoint = $context.Entrypoint }
# Guard the assignment, not just the use: PowerShell enforces a ValidateSet on
# every assignment to the parameter variable, not only at binding. A session
# whose transcript records no effort resolves to $null here, and assigning that
# throws "the value  is not a valid value for the Effort variable" before any
# of the code below runs. Sessions created by `claude -p` record no effort field
# at all (verified 2026-08-09, CLI 2.1.220), so this is reachable, not
# theoretical. Leaving $Effort empty is correct: STEP 2 below omits the key.
if (-not $Effort -and $context.Effort) { $Effort = $context.Effort }

# A probe-only log, kept apart from the real keepwarm's ping log.
$probeLog = Join-Path $env:TEMP "claude-keepwarm-probe-$SessionId.log"

# STEP 2 — send one real ping with those keys.
$pingArgs = @{
    SessionId  = $SessionId
    ProjectDir = $context.ProjectDir
    LogPath    = $probeLog
}
if ($Entrypoint) { $pingArgs['Entrypoint'] = $Entrypoint }
if ($Effort) { $pingArgs['Effort'] = $Effort }

# No -StatePath and no -TaskName: a probe must not establish a high-water mark
# a later real keepwarm would inherit, and must never unregister anything.
$result = & (Join-Path $scriptDir 'Ping-ClaudeSession.ps1') @pingArgs

# The ping could not be made at all — no verdict is possible, so say that
# rather than reporting a divergence that was never measured.
if ($result.Status -eq 'ERROR') {
    [PSCustomObject]@{
        Verdict      = 'ProbeFailed'
        Detail       = $result.Detail
        SessionId    = $SessionId
        ProjectDir   = $context.ProjectDir
        Entrypoint   = $Entrypoint
        Effort       = $Effort
        ProbeLogPath = $probeLog
    }
    return
}

# STEP 3 — turn the read/write split into a verdict. What fraction of the whole
# prefix came from cache is the entire signal: near 1 means it was read, low
# means it was rewritten.
$prefix = $result.CacheRead + $result.CacheWrite
$readFraction = if ($prefix -gt 0) { [math]::Round($result.CacheRead / [double]$prefix, 4) } else { 0 }

# A warm resume reads essentially the whole prefix. Between 0.5 and 0.9 the
# lineage is right but turns have accumulated on it since its last request —
# expected on a first probe, and it settles on the next ping. Below 0.5 the
# read collapsed, which is the divergence signature.
$verdict = if ($readFraction -ge 0.9) { 'Warm' }
    elseif ($readFraction -ge 0.5) { 'WarmWithBacklog' }
    else { 'Diverged' }

# Each verdict carries the action it implies, so a caller reporting this does
# not have to know the reasoning to give the right advice.
$advice = switch ($verdict) {
    'Warm' { 'Pings with these keys land on the session lineage. Safe to schedule.' }
    'WarmWithBacklog' { 'Right lineage, but turns have accumulated on it. Probe again; if it does not settle above 0.9, the keys are wrong.' }
    'Diverged' { "This invocation is not hitting the session's lineage — it rewrote most of the prefix. Scheduling it would pay full-rewrite prices all night and leave the session cold anyway. Check that Entrypoint matches the session's own." }
}

[PSCustomObject]@{
    Verdict          = $verdict
    Advice           = $advice
    SessionId        = $SessionId
    ProjectDir       = $context.ProjectDir
    Entrypoint       = $Entrypoint
    EntrypointSource = $context.EntrypointSource
    Effort           = $Effort
    CacheRead        = $result.CacheRead
    CacheWrite       = $result.CacheWrite
    PrefixTokens     = $prefix
    ReadFraction     = $readFraction
    CostUsd          = $result.CostUsd
    # A 1-hour-TTL cache write bills at 2x base input and a read at 0.1x
    # (Anthropic's prompt-caching documentation, read 2026-08-07), so a full
    # rewrite costs about 20 warm pings regardless of which model is in use.
    BreakEvenPings   = 20
    ProbeLogPath     = $probeLog
}
