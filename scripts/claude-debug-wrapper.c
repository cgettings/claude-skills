/*
 * claude-debug-wrapper — launches the real Claude Code binary with debug output
 * routed to a file instead of to stderr.
 *
 * WHY THIS EXISTS: the extension already passes --debug, so enabling debug was
 * never the problem. It passes --debug-to-stderr immediately after, and that
 * flag suppresses the on-disk log entirely — which is why debug output appears
 * in the Output panel and ~/.claude/debug/ stays empty for extension sessions.
 * Measured 2026-08-30 against native-binary 2.1.251, `claude … mcp list`:
 *   --debug                                  -> 41,519-byte file in ~/.claude/debug/
 *   --debug --debug-to-stderr                -> no file
 *   --debug --debug-to-stderr --debug-file P -> no file (stderr wins over an
 *                                               explicit path, so no appended
 *                                               flag can undo it)
 * Since nothing can be added to counteract it, the flag has to be removed from
 * the command line before the real binary sees it.
 *
 * The VS Code extension offers no way to alter CLI flags, but
 * `claudeCode.claudeProcessWrapper` lets us substitute the executable — the
 * extension then passes the real binary path as our first argument
 * (extension.js: `executableArgs: X ? [X] : []`).
 *
 * TRADEOFF: with --debug-to-stderr gone, debug lines stop appearing in the
 * VS Code Output panel. They land in ~/.claude/debug/<session-uuid>.txt instead,
 * which is the point.
 *
 * SECOND TRADEOFF, and it is not this file's to fix: merely *configuring*
 * claudeCode.claudeProcessWrapper costs auto permission mode. The extension
 * passes `resolvePermissionModeInCli: !y$("claudeProcessWrapper")`, and the SDK
 * reads that as `mode ?? (resolveInCli ? undefined : "default")` — so with a
 * wrapper set the extension always names a mode on the command line and the
 * CLI's own `permissions.defaultMode` never gets to resolve. auto is not in
 * claudeCode.initialPermissionMode's enum, so no setting can name it either.
 * (The extension also skips its one-time clearPersistedPermissionModeForAutoDefault
 * migration when a wrapper is configured.) Deleting the wrapper setting is the
 * only way back to auto. [read from extension.js, 2.1.251, 2026-08-31]
 *
 * THIS WRAPPER MUST NOT ADD FLAGS TO SUBCOMMANDS. Only the session launch takes
 * --debug; the subcommand trees reject it and exit before doing anything:
 *   claude plugin list --debug -> exit 1, "error: unknown option '--debug'"
 *   claude plugin list         -> exit 0  [verified 2026-08-31, CLI 2.1.236]
 * An earlier version appended --debug unconditionally, which broke every
 * `claude plugin …` call the extension makes. The append is now gated on
 * --debug-to-stderr being present, which is true of the session launch and of
 * nothing else.
 *
 * WHY A .exe AND NOT A .cmd: the Agent SDK spawns this with
 * {cwd, stdio, signal, env, windowsHide} and no `shell: true`. Node refuses to
 * spawn .cmd/.bat without a shell (CVE-2024-27980 mitigation), so a batch file
 * would fail with EINVAL before it ever ran.
 *
 * WHERE THIS LIVES: this file is the only copy of the source, and it is not
 * where the binary runs from. The .exe is deployed to ~/.claude/scripts/, which
 * is what claudeCode.claudeProcessWrapper points at; ~/.claude/scripts/ holds no
 * source, only claude-debug-wrapper.exe and the previous build as .prev.exe.
 * Keeping one copy is deliberate — this repo has been bitten before by a value
 * maintained by hand in two files with nothing holding them equal.
 *
 * Build: clang -O2 -municode -o claude-debug-wrapper.exe claude-debug-wrapper.c
 *   -municode is required: without it the mingw CRT looks for WinMain and the
 *   link fails with "undefined symbol: WinMain" against this file's wmain.
 *   On this machine clang is at /c/msys64/clang64/bin/clang (20.1.5, target
 *   x86_64-w64-windows-gnu) and is not on PATH by default.
 *
 * Deploy, from the repo root (the built .exe is gitignored):
 *   clang -O2 -municode -o scripts/claude-debug-wrapper.exe scripts/claude-debug-wrapper.c
 *   mv ~/.claude/scripts/claude-debug-wrapper.exe ~/.claude/scripts/claude-debug-wrapper.prev.exe
 *   mv scripts/claude-debug-wrapper.exe ~/.claude/scripts/claude-debug-wrapper.exe
 * Build to a path inside the repo rather than to /tmp: clang is a Windows
 * program, so a literal /tmp/… from Git Bash resolves against the current drive
 * and not the shell's /tmp. The rename in step 2 is the point — see the swap
 * note below.
 *
 * Test before deploying. Build a program that prints GetCommandLineW() and run
 * the wrapper in front of it; the transform is then readable directly. The four
 * cases that matter, all verified 2026-08-31 on the build this file describes:
 *   plugin list --json                -> unchanged (nothing appended)
 *   --debug --debug-to-stderr         -> one --debug, stderr flag gone
 *   --debug-to-stderr alone           -> --debug appended, stderr flag gone
 *   -p "say --debug-to-stderr aloud"  -> quoted text survives, nothing appended
 * The third case is the positive control: without it, a wrapper that simply
 * never appends passes the other three.
 *
 * Swapping in a rebuild while sessions are live: Windows blocks overwriting a
 * running .exe but permits renaming one, so move the old file aside and rename
 * the new one into place. Running sessions keep the old image; new ones pick up
 * the new binary without VS Code being restarted.
 */

#include <windows.h>
#include <shellapi.h>
#include <stdio.h>

/* Advance past one token of a Windows command line, honoring double quotes. */
static wchar_t *skip_first_token(wchar_t *p) {
    int in_quotes = 0;
    while (*p == L' ' || *p == L'\t') p++;
    while (*p && (in_quotes || (*p != L' ' && *p != L'\t'))) {
        if (*p == L'"') in_quotes = !in_quotes;
        p++;
    }
    while (*p == L' ' || *p == L'\t') p++;
    return p;
}

/* Is one whitespace-delimited token present, unquoted, in this command line?
   Same boundary and quote rules as strip_token below. */
static int has_token(const wchar_t *s, const wchar_t *tok) {
    size_t toklen = wcslen(tok);
    int in_quotes = 0;

    for (const wchar_t *r = s; *r; r++) {
        if (*r == L'"') { in_quotes = !in_quotes; continue; }
        if (in_quotes) continue;
        if (r != s && r[-1] != L' ' && r[-1] != L'\t') continue;
        if (wcsncmp(r, tok, toklen) != 0) continue;
        wchar_t after = r[toklen];
        if (after == L'\0' || after == L' ' || after == L'\t') return 1;
    }
    return 0;
}

/* Delete every unquoted occurrence of one whitespace-delimited token from a
   command line, in place. Quote-state tracking keeps a prompt or file path that
   happens to contain the flag text from being mangled — the extension's own
   argv never does, but the wrapper sits in front of every launch. */
static void strip_token(wchar_t *s, const wchar_t *tok) {
    size_t toklen = wcslen(tok);
    int in_quotes = 0;
    wchar_t *r = s, *w = s;

    while (*r) {
        if (*r == L'"') in_quotes = !in_quotes;

        /* A candidate must start at a token boundary and end at one. */
        int at_start = (r == s) || (r[-1] == L' ') || (r[-1] == L'\t');
        if (!in_quotes && at_start && wcsncmp(r, tok, toklen) == 0) {
            wchar_t after = r[toklen];
            if (after == L'\0' || after == L' ' || after == L'\t') {
                r += toklen;
                while (*r == L' ' || *r == L'\t') r++;   /* eat the separator too */
                /* Avoid leaving a double space where the token used to be. */
                if (w > s && (w[-1] == L' ' || w[-1] == L'\t') && *r) continue;
                if (!*r && w > s) { while (w > s && (w[-1] == L' ' || w[-1] == L'\t')) w--; }
                continue;
            }
        }
        *w++ = *r++;
    }
    *w = L'\0';
}

int wmain(void) {
    int argc = 0;
    wchar_t **argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (!argv || argc < 2) {
        fwprintf(stderr, L"claude-debug-wrapper: expected the real claude binary as argv[1]\n");
        return 2;
    }

    /* Reuse the tail of our own command line verbatim rather than re-quoting
       argv ourselves: it already starts with the real binary path as token 0,
       which is exactly the form CreateProcessW wants, and Node's quoting
       survives untouched. */
    wchar_t *tail = skip_first_token(GetCommandLineW());

    /* --debug-to-stderr is the signature of the launch this wrapper exists for,
       and it is on no other invocation. Gating the append on it keeps the
       belt-and-braces behaviour where it belongs — if the extension ever stops
       passing --debug, debug is still forced on for the session — while leaving
       `claude plugin …`, `claude mcp …` and `claude auth …` byte-identical to
       what the extension sent. See the header for what the append used to break. */
    int force_debug = has_token(tail, L"--debug-to-stderr") &&
                      !has_token(tail, L"--debug");

    size_t len = wcslen(tail) + wcslen(L" --debug") + 1;
    wchar_t *cmdline = (wchar_t *)malloc(len * sizeof(wchar_t));
    if (!cmdline) return 2;
    if (force_debug) {
        _snwprintf(cmdline, len, L"%s --debug", tail);
    } else {
        _snwprintf(cmdline, len, L"%s", tail);
    }

    /* The one edit that actually matters — see the header comment. */
    strip_token(cmdline, L"--debug-to-stderr");

    STARTUPINFOW si = { .cb = sizeof(si) };
    PROCESS_INFORMATION pi = { 0 };

    /* Inherit handles so the SDK's stdio pipes reach the real CLI unchanged. */
    if (!CreateProcessW(argv[1], cmdline, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
        fwprintf(stderr, L"claude-debug-wrapper: CreateProcess failed (%lu) for %s\n",
                 GetLastError(), argv[1]);
        return 2;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD code = 1;
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return (int)code;
}
