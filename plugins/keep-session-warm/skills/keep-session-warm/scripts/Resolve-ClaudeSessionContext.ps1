<#
.SYNOPSIS
    Locates a Claude Code session's transcript and reads the two values that
    determine which prompt-cache lineage a resume lands on.

.DESCRIPTION
    Dot-source this to define Resolve-ClaudeSessionContext. Both
    Start-ClaudeKeepwarm.ps1 and Test-ClaudeCacheLineage.ps1 need the same
    lookup, and a keepwarm that pins different lineage keys than the checker
    verifies would report a success it never delivered.

.EXAMPLE
    . .\Resolve-ClaudeSessionContext.ps1
    $context = Resolve-ClaudeSessionContext -SessionId $id -ProjectDir $dir
#>

function Resolve-ClaudeSessionContext {
    <#
    .SYNOPSIS
        Resolves a session's transcript path, entrypoint, and effort level.

    .PARAMETER SessionId
        The session id to resolve.

    .PARAMETER ProjectDir
        The directory the session was created in.

    .OUTPUTS
        PSCustomObject with SessionId, ProjectDir, TranscriptPath, Entrypoint,
        and Effort. Throws when no transcript exists for the pairing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SessionId,
        [Parameter(Mandatory)][string]$ProjectDir
    )

    # STEP 1 — work out where this session's transcript should be.
    $resolvedDir = (Resolve-Path -LiteralPath $ProjectDir -ErrorAction Stop).Path

    # Sessions live under ~/.claude/projects/<cwd with : \ / replaced by ->/<id>.jsonl.
    # Resolving here turns a 3am "No conversation found" into a failure now.
    $projectsRoot = Join-Path $env:USERPROFILE '.claude\projects'
    $expectedDir = Join-Path $projectsRoot ($resolvedDir -replace '[:\\/]', '-')
    $transcript = Join-Path $expectedDir "$SessionId.jsonl"

    # Not there: search every project directory so the error can say where the
    # session actually lives, which is nearly always a wrong -ProjectDir.
    if (-not (Test-Path -LiteralPath $transcript)) {
        $found = Get-ChildItem -LiteralPath $projectsRoot -Filter "$SessionId.jsonl" -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        $hint = if ($found) {
            "It exists under '$($found.Directory.Name)', so -ProjectDir is probably wrong: --resume only finds a session from the directory that created it."
        } else {
            'No transcript with that id exists under any project directory.'
        }
        throw "No transcript for session '$SessionId' under '$expectedDir'. $hint"
    }

    # STEP 2 — parse the last 200 transcript lines into objects. The transcript
    # is JSONL, one JSON object per line; unparseable lines are skipped.
    # Read the tail rather than the whole file — a long session's transcript is
    # large, and both lineage keys are recorded on every turn.
    $tail = Get-Content -LiteralPath $transcript -Tail 200 -ErrorAction SilentlyContinue
    $recent = foreach ($line in $tail) {
        try { $line | ConvertFrom-Json -ErrorAction Stop } catch { }
    }

    # STEP 3 — lineage key one: the entrypoint. Live environment beats transcript.
    # When this runs inside the session being protected, the live environment is
    # ground truth and the transcript is not: a single stray ping under the
    # wrong entrypoint becomes the newest turn, and reading "the last value"
    # would then pin the keepwarm to precisely the lineage that stray ping
    # created. Observed while testing this script.
    $entrypoint = $null
    $entrypointSource = 'Transcript'
    if ($SessionId -eq $env:CLAUDE_CODE_SESSION_ID -and $env:CLAUDE_CODE_ENTRYPOINT) {
        $entrypoint = $env:CLAUDE_CODE_ENTRYPOINT
        $entrypointSource = 'Environment'
    }
    if (-not $entrypoint) {
        $entrypoint = ($recent | Where-Object { $_.entrypoint } | Select-Object -Last 1).entrypoint
    }

    # STEP 4 — lineage key two: the effort level.
    # Take effort from the newest turn that ran on the lineage being targeted,
    # not simply the newest turn, for the same reason.
    $effort = $null
    if ($entrypoint) {
        $effort = ($recent | Where-Object { $_.effort -and $_.entrypoint -eq $entrypoint } | Select-Object -Last 1).effort
    }
    # Fall back to the newest turn of any lineage rather than returning nothing.
    if (-not $effort) {
        $effort = ($recent | Where-Object { $_.effort } | Select-Object -Last 1).effort
    }

    # STEP 5 — hand back both keys plus where the entrypoint came from, so the
    # caller can tell a measured value from an inferred one.
    [PSCustomObject]@{
        SessionId        = $SessionId
        ProjectDir       = $resolvedDir
        TranscriptPath   = $transcript
        Entrypoint       = $entrypoint
        EntrypointSource = $entrypointSource
        Effort           = $effort
    }
}
