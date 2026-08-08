<#
.SYNOPSIS
    Reads the reason the API gave for a prompt-cache miss out of a session
    transcript.

.DESCRIPTION
    Dot-source this to define Get-CacheMissReason. Ping-ClaudeSession.ps1 uses
    it to tell a diverged lineage apart from a rewritten prompt prefix, which
    produce identical read/write numbers and call for opposite responses.

    The value only exists in the transcript. `claude -p --output-format json`
    reports usage but carries no diagnostics object at all (verified
    2026-08-08), so there is nothing to read on the command's own output.

.EXAMPLE
    . .\Get-CacheMissReason.ps1
    $reason = Get-CacheMissReason -Read 0 -Write 58782 -SessionId $id -ProjectDir $dir
#>

function Get-CacheMissReason {
    <#
    .SYNOPSIS
        Returns the cache_miss_reason type for the ping with the given cache
        read/write counts, or $null when it cannot be determined.

    .DESCRIPTION
        $null means "unknown" and must never be read as "healthy". The field is
        genuinely absent on some real misses — a cold session measured
        read=0 write=39062 with no diagnostics object — which is why this
        classifies a miss the caller already detected rather than detecting one.

        The record is located by matching the ping's own read and write counts.
        That matters for two reasons: the transcript may not be flushed when
        `claude` exits, and the result JSON's uuid matches no transcript record
        (result uuid 5fd06fea-..., assistant record a9651dba-..., verified
        2026-08-08). Taking "the newest assistant record" would therefore return
        the *previous* turn's reason during the flush window, which is worse
        than returning nothing.

    .PARAMETER Read
        cache_read_input_tokens for the ping being classified.

    .PARAMETER Write
        cache_creation_input_tokens for the ping being classified.

    .PARAMETER TranscriptPath
        Transcript to read. Resolved from SessionId and ProjectDir when omitted.

    .PARAMETER SessionId
        Session to resolve a transcript for. Ignored when TranscriptPath is set.

    .PARAMETER ProjectDir
        Directory that session was created in. Ignored when TranscriptPath is set.

    .PARAMETER TimeoutMs
        How long to keep re-reading while waiting for the ping's own record to
        be flushed. 0 reads exactly once.

    .PARAMETER TailLines
        Transcript lines to scan back through. The default covers a ping's own
        turn; a whole-file scan is only wanted for offline analysis.

    .OUTPUTS
        String reason type, or $null.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Read,
        [Parameter(Mandatory)][int]$Write,
        [string]$TranscriptPath,
        [string]$SessionId,
        [string]$ProjectDir,
        [int]$TimeoutMs = 500,
        [int]$TailLines = 50
    )

    # Resolve the transcript only when the caller did not supply one, and treat
    # every failure as "unknown" — this runs unattended on the miss path, where
    # throwing would lose the log line that explains the miss.
    if (-not $TranscriptPath) {
        $resolver = Join-Path $PSScriptRoot 'Resolve-ClaudeSessionContext.ps1'
        if (-not (Test-Path -LiteralPath $resolver)) { return $null }
        try {
            . $resolver
            $TranscriptPath = (Resolve-ClaudeSessionContext -SessionId $SessionId -ProjectDir $ProjectDir).TranscriptPath
        } catch {
            return $null
        }
    }

    $deadline = [datetime]::UtcNow.AddMilliseconds($TimeoutMs)
    do {
        $tail = @(Get-Content -LiteralPath $TranscriptPath -Tail $TailLines -ErrorAction SilentlyContinue)
        for ($i = $tail.Count - 1; $i -ge 0; $i--) {
            try { $record = $tail[$i] | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ($record.type -ne 'assistant') { continue }
            $usage = $record.message.usage
            if ($null -eq $usage) { continue }
            if ([int]$usage.cache_read_input_tokens -ne $Read) { continue }
            if ([int]$usage.cache_creation_input_tokens -ne $Write) { continue }
            return $record.message.diagnostics.cache_miss_reason.type
        }
        if ($TimeoutMs -gt 0) { Start-Sleep -Milliseconds 50 }
    } while ([datetime]::UtcNow -lt $deadline)

    return $null
}
