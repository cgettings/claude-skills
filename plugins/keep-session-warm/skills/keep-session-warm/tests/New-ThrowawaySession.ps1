<#
.SYNOPSIS
    Creates a throwaway Claude Code session, pinned to Haiku, for the live
    keep-session-warm tests to spend real API cost against without ever
    touching the caller's own working session.

.DESCRIPTION
    Dot-source this to define New-ThrowawaySession and Remove-ThrowawaySession.
    Every live test in this directory calls New-ThrowawaySession for its own
    disposable session rather than accepting -SessionId from the environment —
    see Ground rule 1 in PLAN-live-test-coverage.md.

    The throwaway's prefix is a `claude -p` system prompt plus one turn, so a
    full-prefix rewrite bought against it is cheap regardless of which model it
    runs on. What is NOT invariant is the base input price, so the throwaway is
    pinned to Haiku 4.5 at creation and never repinned — see PLAN-live-test-coverage.md
    Ground rule 4. Step 6 below verifies that pin survives a --resume with no
    --model flag, because Ping-ClaudeSession.ps1 never passes one either.

.PARAMETER MaxSpendUsd
    Aborts with a clear message the moment cumulative cost from the calls this
    function itself makes would exceed this. Callers track their own spend on
    top of this session's creation cost.

.OUTPUTS
    New-ThrowawaySession: PSCustomObject with SessionId, ProjectDir,
    Entrypoint, Model, Effort, ModelPinHolds, PrefixTokens, TranscriptPath,
    CostUsd, and FirstResumeRead/FirstResumeWrite/FirstResumeReason — the one
    real cache miss this harness observes (see the STEP 6 comment).

    Remove-ThrowawaySession: none. Deletes the transcript and scratch project
    directory for the given session object.
#>

# Captured at dot-source time. $PSCommandPath inside the function below is the
# *calling* script's path once dot-sourced, and $null when called from an
# interactive prompt — neither locates scripts/ reliably.
$KeepwarmTestsDir = $PSScriptRoot

function New-ThrowawaySession {
    [CmdletBinding()]
    param(
        [double]$MaxSpendUsd = 1.00
    )

    $ErrorActionPreference = 'Stop'
    $spent = 0.0

    # Pure predicate, deliberately not a mutator: a nested function's $script:
    # scope is the *dot-sourcing* script's scope, not this function's, so an
    # accumulator kept there would tangle with the caller's own $spent.
    function Assert-SpendCap {
        param([double]$Spent, [double]$Cap)
        if ($Spent -gt $Cap) {
            throw "Spend cap exceeded: `$$([math]::Round($Spent, 4)) > `$$Cap (New-ThrowawaySession)"
        }
    }

    # `claude -p --output-format json` carries no top-level `model` field
    # (verified 2026-08-09, CLI 2.1.220) — the model actually used is the sole
    # key of `modelUsage`, whose value's `canonicalModel` names it.
    function Get-ResultModel {
        param($Result)
        $prop = $Result.modelUsage.PSObject.Properties | Select-Object -First 1
        if ($prop) { return $prop.Value.canonicalModel }
        return $null
    }

    # STEP 1 — scratch project directory. A random suffix keeps concurrent runs
    # of this suite from colliding on the same PID.
    $suffix = Get-Random -Minimum 1000 -Maximum 9999
    $projectDir = Join-Path $env:TEMP "keepwarm-live-$PID-$suffix"
    New-Item -ItemType Directory -Force -Path $projectDir | Out-Null

    Push-Location -LiteralPath $projectDir
    try {
        # STEP 2 — pin the creating entrypoint to a known value, recording which.
        if ($env:CLAUDE_CODE_ENTRYPOINT) {
            $entrypoint = $env:CLAUDE_CODE_ENTRYPOINT
            $entrypointSource = 'inherited from process'
        } else {
            $entrypoint = 'cli'
            $env:CLAUDE_CODE_ENTRYPOINT = $entrypoint
            $entrypointSource = 'default (was unset)'
        }
        Write-Verbose "Creating entrypoint: $entrypoint ($entrypointSource)"

        # STEP 3 — create the session, pinned to Haiku 4.5.
        #
        # NOTE: a `claude -p` session records no `effort` field in its
        # transcript, and passing --effort does not change that (verified
        # 2026-08-09, CLI 2.1.220: zero matches for "effort" across the 19-line
        # transcript of a session created with `--effort medium`, against 101
        # matches for "effort":"medium" in an interactive session's). So
        # Resolve-ClaudeSessionContext.ps1 resolves Effort to $null for any
        # throwaway, and every caller of it must pass -Effort explicitly.
        # See tests/RESULTS-live-2026-08-09.md — this is a real gap in the
        # scripts, not a property of the harness.
        $json = & claude -p 'Reply with the single word: ready.' --output-format json --model claude-haiku-4-5
        if ($LASTEXITCODE -ne 0) { throw "claude create call failed, exit=$LASTEXITCODE, output: $json" }
        $result = $json | ConvertFrom-Json
        if ($result.is_error -or $result.subtype -ne 'success') {
            throw "create call reported failure: subtype=$($result.subtype) $($result.result)"
        }
        $spent += [double]$result.total_cost_usd
        Assert-SpendCap -Spent $spent -Cap $MaxSpendUsd

        $createdModel = Get-ResultModel -Result $result
        if (-not ($createdModel -like 'claude-haiku-4-5*')) {
            throw "CLI ignored --model claude-haiku-4-5; create call returned model='$createdModel'. Stopping here — everything downstream would bill at the wrong rate."
        }

        $sessionId = $result.session_id
        $model = $createdModel
        $read = [int]$result.usage.cache_read_input_tokens
        $write = [int]$result.usage.cache_creation_input_tokens
        $prefixTokens = $read + $write
        $createCost = [double]$result.total_cost_usd

        # STEP 4 — assert the prefix clears both the Ping-ClaudeSession.ps1
        # MinWriteTokens default (4096) and Haiku 4.5's own 4096-token minimum
        # cacheable prefix. Below that, one more turn and re-measure.
        if ($prefixTokens -le 8192) {
            Write-Verbose "PrefixTokens=$prefixTokens does not clear 8192; sending one more turn."
            $json2 = & claude -p --resume $sessionId 'Reply: ok.' --output-format json
            if ($LASTEXITCODE -ne 0) { throw "top-up resume failed, exit=$LASTEXITCODE, output: $json2" }
            $result2 = $json2 | ConvertFrom-Json
            if ($result2.is_error -or $result2.subtype -ne 'success') {
                throw "top-up resume reported failure: subtype=$($result2.subtype) $($result2.result)"
            }
            $spent += [double]$result2.total_cost_usd
            Assert-SpendCap -Spent $spent -Cap $MaxSpendUsd
            $read = [int]$result2.usage.cache_read_input_tokens
            $write = [int]$result2.usage.cache_creation_input_tokens
            $prefixTokens = $read + $write
            $createCost += [double]$result2.total_cost_usd
            if ($prefixTokens -le 8192) {
                throw "PrefixTokens=$prefixTokens still does not clear 8192 after one top-up turn. Refusing to proceed — pings below the model's minimum cacheable prefix measure nothing."
            }
        }

        # STEP 5 — resolve the transcript path the same way the scripts do.
        $mangled = ($projectDir -replace '[:\\/]', '-')
        $transcriptPath = Join-Path $env:USERPROFILE ".claude\projects\$mangled\$sessionId.jsonl"
        if (-not (Test-Path -LiteralPath $transcriptPath)) {
            throw "Expected transcript not found at '$transcriptPath'."
        }

        # STEP 6 — verify the model pin survives a resume with NO --model flag,
        # the same way Ping-ClaudeSession.ps1 invokes claude. The whole suite's
        # per-dollar figures rest on this holding.
        $json3 = & claude -p --resume $sessionId 'Reply: ok.' --output-format json
        if ($LASTEXITCODE -ne 0) { throw "pin-verification resume failed, exit=$LASTEXITCODE, output: $json3" }
        $result3 = $json3 | ConvertFrom-Json
        if ($result3.is_error -or $result3.subtype -ne 'success') {
            throw "pin-verification resume reported failure: subtype=$($result3.subtype) $($result3.result)"
        }
        $spent += [double]$result3.total_cost_usd
        Assert-SpendCap -Spent $spent -Cap $MaxSpendUsd
        $createCost += [double]$result3.total_cost_usd

        $pinModel = Get-ResultModel -Result $result3
        $pinRead = [int]$result3.usage.cache_read_input_tokens
        $pinWrite = [int]$result3.usage.cache_creation_input_tokens
        $modelPinHolds = [bool]($pinModel -like 'claude-haiku-4-5*')

        $scriptDir = Join-Path (Split-Path -Parent $KeepwarmTestsDir) 'scripts'
        $reasonHelper = Join-Path $scriptDir 'Get-CacheMissReason.ps1'
        $pinReason = $null
        if (Test-Path -LiteralPath $reasonHelper) {
            . $reasonHelper
            $pinReason = Get-CacheMissReason -Read $pinRead -Write $pinWrite -TranscriptPath $transcriptPath
        }

        Write-Host "Model pin check: model=$pinModel read=$pinRead write=$pinWrite reason=$pinReason ModelPinHolds=$modelPinHolds"

        if (-not $modelPinHolds) {
            Write-Warning "Model pin did NOT hold: resume returned model='$pinModel' (reason=$pinReason). Re-creating the throwaway with NO --model flag (this machine's current default, currently Sonnet 5) rather than proceeding on a session whose resumes silently switch models."

            # Recreate with no --model flag at all.
            $json4 = & claude -p 'Reply with the single word: ready.' --output-format json
            if ($LASTEXITCODE -ne 0) { throw "unpinned recreate failed, exit=$LASTEXITCODE, output: $json4" }
            $result4 = $json4 | ConvertFrom-Json
            if ($result4.is_error -or $result4.subtype -ne 'success') {
                throw "unpinned recreate reported failure: subtype=$($result4.subtype) $($result4.result)"
            }
            $spent += [double]$result4.total_cost_usd
            Assert-SpendCap -Spent $spent -Cap $MaxSpendUsd

            $sessionId = $result4.session_id
            $model = Get-ResultModel -Result $result4
            $read = [int]$result4.usage.cache_read_input_tokens
            $write = [int]$result4.usage.cache_creation_input_tokens
            $prefixTokens = $read + $write
            $createCost += [double]$result4.total_cost_usd
            $transcriptPath = Join-Path $env:USERPROFILE ".claude\projects\$mangled\$sessionId.jsonl"

            if ($prefixTokens -le 8192) {
                $json5 = & claude -p --resume $sessionId 'Reply: ok.' --output-format json
                if ($LASTEXITCODE -ne 0) { throw "unpinned top-up failed, exit=$LASTEXITCODE, output: $json5" }
                $result5 = $json5 | ConvertFrom-Json
                $spent += [double]$result5.total_cost_usd
                Assert-SpendCap -Spent $spent -Cap $MaxSpendUsd
                $read = [int]$result5.usage.cache_read_input_tokens
                $write = [int]$result5.usage.cache_creation_input_tokens
                $prefixTokens = $read + $write
                $createCost += [double]$result5.total_cost_usd
                if ($prefixTokens -le 8192) {
                    throw "Unpinned recreate's PrefixTokens=$prefixTokens still does not clear 8192 after a top-up turn."
                }
            }
        } else {
            $model = $pinModel
        }

        # STEP — expected result.
        $session = [PSCustomObject]@{
            SessionId        = $sessionId
            ProjectDir       = $projectDir
            Entrypoint       = $entrypoint
            EntrypointSource = $entrypointSource
            Model            = $model
            # Not resolved from the transcript — a `claude -p` session records
            # no effort at all (see STEP 3). This is the level callers must
            # pass explicitly to every probe/ping against this session.
            Effort           = 'medium'
            ModelPinHolds    = $modelPinHolds
            # The STEP 6 resume is the one place this harness observes a real
            # cache miss with a real reason: the first --resume after a
            # `claude -p` create reliably reports system_changed with a large
            # write (18,269 read / ~14,230 write on every throwaway created
            # 2026-08-09). Later pings all read the full prefix. Surfaced
            # because it is measured evidence no other test here can buy —
            # Test-LiveMissAbort.ps1 reports it rather than discarding it.
            FirstResumeRead   = $pinRead
            FirstResumeWrite  = $pinWrite
            FirstResumeReason = $pinReason
            PrefixTokens     = $prefixTokens
            TranscriptPath   = $transcriptPath
            CostUsd          = [math]::Round($createCost, 4)
        }
        $session | Format-List | Out-String | Write-Host
        return $session
    } finally {
        Pop-Location
    }
}

function Remove-ThrowawaySession {
    <#
    .SYNOPSIS
        Deletes a throwaway session's transcript directory and scratch project
        directory. Never touches a scheduled task or state file — callers that
        registered either are responsible for their own cleanup.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$Session
    )

    # Ping-ClaudeSession.ps1 sets the process location into -ProjectDir and does
    # not restore it, so at this point the shell is very likely standing inside
    # the directory being deleted — Remove-Item then fails, and with
    # -ErrorAction SilentlyContinue it fails silently. Leave first.
    Set-Location -LiteralPath $env:USERPROFILE

    $transcriptDir = Split-Path -Parent $Session.TranscriptPath
    Remove-Item -LiteralPath $transcriptDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Session.ProjectDir -Recurse -Force -ErrorAction SilentlyContinue

    # Cleanup that cannot be observed is not cleanup. These run in a finally
    # block, so warn rather than throw — a cleanup failure must not mask the
    # test failure that sent us here.
    foreach ($leftover in @($transcriptDir, $Session.ProjectDir)) {
        if (Test-Path -LiteralPath $leftover) {
            Write-Warning "Remove-ThrowawaySession left '$leftover' behind; delete it by hand."
        }
    }
}
