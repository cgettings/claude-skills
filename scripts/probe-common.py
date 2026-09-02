#!/usr/bin/env python3
"""The `claude -p` harness shared by measure-rule-firing.py and screen-queries.py.

Extracted 2026-09-01 because STRIP_ENV had to be correct in both and nothing kept
them equal. ANTHROPIC_BASE_URL and HTTPS_PROXY were added to it after
screen-queries.py was written; the next variable that needs stripping would have
to be remembered twice, and forgetting the second copy produces empty responses
that read as "the probe is dead" rather than as a broken harness -- a licensed
conclusion about the split from a run that measured nothing.

`judge()` is deliberately NOT here. The two scripts' judge prompts differ in
their negative examples (measure-rule-firing.py excludes "add coverage" and
"it depends"; screen-queries.py excludes "double-check"), so a single copy would
silently change what one of them scored -- and the numbers in
docs/durable-memory-model.md were produced by those prompts as they stand.

Import by NAME, not as `probe_common.claude(...)`: rejudge-on-opus.py rebinds
`mrf.claude` to a longer-timeout wrapper and relies on the importing module's
own `judge` resolving `claude` through its module globals.
"""
import json
import os
import subprocess
import threading
import time
from pathlib import Path

# Four variables that all produce the SAME wrong answer by different routes:
# every response comes back empty, the arms are indistinguishable, and the run
# reads as "A~=B~=C, probe is dead" -- a licensed conclusion about the split --
# rather than as a broken harness. Stripped rather than detected, because a
# detector only helps if someone reads its output.
#
#   ANTHROPIC_LOG    prepends the SDK's request dump to STDOUT, breaking the
#                    stream-json parse below on its first character.
#                    [verified 2026-08-28 on claude-cli/2.1.227]
#   ANTHROPIC_BASE_URL,
#   HTTPS_PROXY,
#   https_proxy      point the probes at Task 9 step 2's logging proxy, which
#                    answers with a stub. The parse succeeds and the content is
#                    empty, so this one leaves no error at all. Both spellings
#                    of the proxy var occur in the installed binary, so both are
#                    stripped -- stripping one that turns out to be ignored
#                    costs nothing, missing one that is honoured costs a run.
STRIP_ENV = {"CLAUDECODE", "ANTHROPIC_LOG", "ANTHROPIC_BASE_URL",
             "HTTPS_PROXY", "https_proxy"}

# Pinned, because an unpinned `claude -p` resolves from ~/.claude/settings.json
# ("model": "sonnet" on this machine), which makes the experiment depend on
# ambient config: a settings edit, or a /model in some other session, silently
# changes what was measured.
#
# Sonnet rather than Opus is the conservative direction, and the reasoning is
# the point. Step 5 asks whether trimming evidence out of a rule degrades
# firing. A more capable model can infer from a trimmed rule what a weaker one
# cannot -- so a PASS on Opus would greenlight a split that might still break
# Sonnet sessions, while a PASS on Sonnet implies Opus passes too. Test on the
# weaker arm. Revisit only if every session these rules serve runs on Opus.
PROBE_MODEL = "claude-sonnet-5"

SUFFIX = ("\n\nAnswer in prose in this turn. Do not use tools and do not ask "
          "clarifying questions -- give your actual assessment.")


def claude(prompt: str, cwd: Path, model: str | None = None,
           timeout: int = 240) -> str:
    """One `claude -p`, returning the assistant's text. Empty string on failure."""
    env = {k: v for k, v in os.environ.items() if k not in STRIP_ENV}
    cmd = ["claude", "-p", prompt]
    if model:
        cmd += ["--model", model]
    try:
        r = subprocess.run(cmd, capture_output=True, encoding="utf-8",
                           errors="replace", env=env, cwd=str(cwd), timeout=timeout)
        return (r.stdout or "").strip()
    except subprocess.TimeoutExpired:
        return ""


def run_probe(query: str, cwd: Path, timeout: int = 240) -> dict:
    """One probe run; capture the whole first assistant text turn plus usage."""
    env = {k: v for k, v in os.environ.items() if k not in STRIP_ENV}
    proc = subprocess.Popen(
        ["claude", "-p", query + SUFFIX, "--model", PROBE_MODEL,
         "--output-format", "stream-json",
         "--verbose", "--include-partial-messages"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, env=env, cwd=str(cwd))
    out = {"text": "", "usage": None, "model": None, "stopped": None, "ms": None}
    started = time.time()
    killer = threading.Timer(timeout, proc.kill)
    killer.start()
    try:
        for raw in proc.stdout:
            try:
                ev = json.loads(raw.decode("utf-8", "replace").strip())
            except json.JSONDecodeError:
                continue
            if ev.get("type") != "stream_event":
                continue
            se = ev.get("event", {})
            k = se.get("type", "")
            if k == "message_start":
                m = se.get("message", {})
                out["model"], out["usage"] = m.get("model"), m.get("usage")
            elif k == "content_block_delta":
                d = se.get("delta", {})
                if d.get("type") == "text_delta":
                    out["text"] += d.get("text", "")
            elif k == "message_stop":
                out["stopped"] = "message-stop"
                break
        else:
            out["stopped"] = "stream-exhausted"
    finally:
        killer.cancel()
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        proc.stdout.close()
    out["ms"] = int((time.time() - started) * 1000)
    return out
