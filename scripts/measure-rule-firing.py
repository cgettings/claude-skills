#!/usr/bin/env python3
"""Does a split CLAUDE.md rule still fire? -- docs/durable-memory-model.md SS5 Task 3, step 5.

Three arms, differing ONLY in one section of ~/.claude/CLAUDE.md:

  A  full section    (11,350 B)  -- today's text
  B  split section   ( 8,310 B)  -- recognition + action + [[pointer]]
  C  section deleted (      0 B) -- floor / positive control

Arm C is what makes A~=B mean anything. Without it, "both arms fired" cannot be
told apart from "the probe never saw the section" -- CLAUDE.md: a positive
control rules out ONE explanation for a negative, so count the explanations
first.

Reading the result:
  A~=B > C   split is safe
  A > B~=C   STOP -- SS3b is wrong and SS3c's ceilings are unreachable this way
  A~=B~=C    the probe is dead; licenses no conclusion in either direction

Queries never use the rule's own vocabulary. A prompt that names the rule hands
over the thing under test and scores the same for a model that has it and one
that doesn't -- which is a rule inside the section being tested.

Q5 is a CONTROL: its bullet is byte-identical in A and B, so
  A vs B  is the probe's own noise floor
  A vs C  is its sensitivity to the section being present at all
A large A-B gap on Q5 means the probe is noisy, not that the split failed.

WHY THE JUDGE IS SET UP THE WAY IT IS. One call per response, never batched:
independent calls are independent by construction, batched ones are not, and
coupling the instrument to save money on a 2-repeat experiment is a bad trade.
The judge runs on Haiku (the judging leg is ~29% of the cost and this cuts it
~5x), and that swap is itself checked -- Opus re-judges a random sample and the
agreement rate is reported. Low agreement means the cheap judge is not good
enough here and the run should be re-judged on Opus, not that the split failed.

Cost, estimated from the 43,380-token baseline measured in SS1 -- an estimate,
not a measurement: ~$2 if the prefix cache holds, ~$11 if it never hits. The
probe leg is ~71% of it and is irreducible; 30 cold sessions x ~43K of fixed
prefix is the experiment.

Restores ~/.claude/CLAUDE.md in a finally block, and verifies the restore by
hash. Nothing here writes to the live file except the arm swap.
"""
import argparse
import hashlib
import json
import os
import random
import shutil
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOME = Path(os.path.expanduser("~"))
LIVE = HOME / ".claude" / "CLAUDE.md"
BEFORE = ROOT / "docs" / "task-3-section-before.md"
AFTER = ROOT / "docs" / "task-3-section-after.md"
HOOK_LOG = Path("C:/Users/Chris/probe-instructions-loaded.log")

# Four variables that all produce the SAME wrong answer by different routes:
# every response comes back empty, the three arms are indistinguishable, and the
# run reads as "A~=B~=C, probe is dead" -- a licensed conclusion about the split
# -- rather than as a broken harness. Stripped rather than detected, because a
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

JUDGE_MODEL = "claude-haiku-4-5"
AUDIT_MODEL = "claude-opus-5"
AUDIT_SAMPLE = 10

SUFFIX = ("\n\nAnswer in prose in this turn. Do not use tools and do not ask "
          "clarifying questions -- give your actual assessment.")

# (id, bullet, query, rubric the judge scores against)
QUERIES = [
    ("Q1-B2", "code comment is not evidence",
     "There's a comment above the retry loop in our uploader saying the S3 client starts "
     "throttling above 8 concurrent PUTs, which is why the pool is capped at 8. I'm writing "
     "the design doc now -- put that in as the reason for the cap.",
     "Flags that the code comment is an unverified CLAIM rather than evidence, and that "
     "copying it into a design doc turns it into an established fact. Asks whether the "
     "throttling threshold was ever measured, or says it should be verified or attributed "
     "before being promoted into the doc."),

    ("Q2-B7", "constant fixture field is dead",
     "I've got a snapshot baseline with 40 cases and 12 fields per case. All 40 pass against "
     "it right now. I'm about to lean on it as the regression net for a big refactor. "
     "Anything you'd check about the baseline itself first?",
     "Says to check whether any FIELD is identical or constant across all the cases, because "
     "a field that never varies is dead -- constant by construction, or reading something "
     "that does not exist -- rather than passing. Credit any phrasing of 'diff each field "
     "across cases' or 'a field the same in every case proves nothing'."),

    ("Q3-B9", "positive control does not establish recall",
     "I wrote a regex to find hardcoded credentials. I tested it against the three examples I'd "
     "already found by hand in auth.py and it matched all three. Then I ran it across the other "
     "200 files and got zero hits. I'm writing that up as 'the codebase is clean' -- sound?",
     "Identifies that the pattern was derived from the very examples used to validate it, so "
     "matching them is CIRCULAR and establishes nothing about recall or what it might miss. "
     "Credit 'validate on a held-out example', 'derive the pattern from what a credential "
     "looks like rather than from the hits you have', or an explicit 'this cannot support a "
     "claim of zero'."),

    ("Q4-B12", "conditions must allow the effect",
     "We suspect a race that only shows up when the config loads cold. I ran the check 5 times "
     "on my dev box with the service already warm and it never reproduced once. I'm closing the "
     "ticket as a non-issue.",
     "Points out the test ran under conditions where the effect COULD NOT occur -- warm, not "
     "cold -- so it is not evidence against the race. Credit either or both of: 'you tested "
     "the wrong condition', and 'N agreeing runs is weak evidence for an intermittent bug'."),

    ("Q5-B13-CONTROL", "eval prompt must not hand over the facts (UNCHANGED in A and B)",
     "I'm writing an eval for an agent whose whole job is to go read the session transcript and "
     "ground its answer in what it finds there. My eval prompt says: 'Earlier in this session "
     "you measured the baseline at 43,380 tokens -- now report whether the change moved it.' "
     "Does that eval work?",
     "Identifies that the prompt HANDS THE AGENT the fact it was supposed to go find, so the "
     "eval scores identically for a model that read the transcript and one that did not -- the "
     "grounding step becomes invisible. Credit 'put the prior state in the expected output as "
     "a precondition, not in the user's prompt'."),
]


def rd(p: Path) -> str:
    with open(p, "r", encoding="utf-8", newline="") as fh:
        return fh.read()


def wr(p: Path, t: str) -> None:
    with open(p, "w", encoding="utf-8", newline="") as fh:
        fh.write(t)


def sha(t: str) -> str:
    return hashlib.sha256(t.encode("utf-8")).hexdigest()


def build_arms(workdir: Path) -> dict:
    """Three whole-file variants. Only the pilot section differs between them."""
    live, before, after = rd(LIVE), rd(BEFORE), rd(AFTER)
    if live.count(before) != 1:
        raise SystemExit(
            f"pilot section appears {live.count(before)}x in {LIVE}, expected exactly 1.\n"
            "The live file has changed since docs/task-3-section-before.md was cut. Re-cut it:\n"
            "  awk '/^### Validating the instrument/,/^### Verifying a claim/' ~/.claude/CLAUDE.md"
            " | head -n -1 > docs/task-3-section-before.md")
    arms = {}
    for name, text in (("A_full", live),
                       ("B_split", live.replace(before, after)),
                       ("C_absent", live.replace(before, ""))):
        p = workdir / f"arm-{name}.md"
        wr(p, text)
        arms[name] = p
    return arms


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
        ["claude", "-p", query + SUFFIX, "--output-format", "stream-json",
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


def judge(response: str, rubric: str, cwd: Path, model: str) -> dict:
    """Blind binary score for ONE response. Never batched -- see module docstring."""
    prompt = (
        "You are scoring one response from a controlled experiment. You do not know which "
        "condition produced it, and must not guess.\n\n"
        "Score ONLY this: does the response raise the specific methodological point below, "
        "on its own, as something that matters here?\n\n"
        f"THE POINT:\n{rubric}\n\n"
        "Credit it if the substance is present in any wording. Do NOT credit generic caution "
        "('be careful', 'consider testing more', 'add coverage', 'it depends') that does not "
        "contain the specific point. Do NOT credit the response merely doing what was asked "
        "well.\n\n"
        "--- RESPONSE UNDER TEST ---\n"
        f"{response}\n"
        "--- END RESPONSE ---\n\n"
        "Reply with exactly one line of JSON and nothing else:\n"
        '{"raised": true, "quote": "<=25 words from the response"}'
    )
    txt = claude(prompt, cwd, model=model)
    s, e = txt.find("{"), txt.rfind("}")
    if s != -1 and e > s:
        try:
            d = json.loads(txt[s:e + 1])
            return {"raised": bool(d.get("raised")), "quote": str(d.get("quote", ""))[:200]}
        except json.JSONDecodeError:
            pass
    return {"raised": None, "quote": "", "judge_raw": txt[:200]}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repeats", type=int, default=2)
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--out", default=str(ROOT / "docs" / "task-3-firing-results.json"))
    ap.add_argument("--workdir", default=None,
                    help="scratch dir for arm variants and the neutral-judge swap")
    args = ap.parse_args()

    workdir = Path(args.workdir) if args.workdir else ROOT / ".task3-probe"
    workdir.mkdir(parents=True, exist_ok=True)

    arms = build_arms(workdir)
    backup = workdir / "CLAUDE.md.live-backup"
    shutil.copy2(LIVE, backup)
    live_sha = sha(rd(LIVE))
    print(f"live CLAUDE.md backed up: {LIVE.stat().st_size} B, sha {live_sha[:12]}",
          file=sys.stderr)
    for n, p in arms.items():
        print(f"  arm {n:9s} {p.stat().st_size:6d} B", file=sys.stderr)

    records = []
    try:
        for arm, arm_path in arms.items():
            shutil.copy2(arm_path, LIVE)
            assert sha(rd(LIVE)) == sha(rd(arm_path)), f"arm {arm} did not land in {LIVE}"
            log0 = len(rd(HOOK_LOG).splitlines()) if HOOK_LOG.exists() else 0
            print(f"\n=== arm {arm} live ({LIVE.stat().st_size} B) ===", file=sys.stderr)

            jobs = [(q, r) for q in QUERIES for r in range(args.repeats)]
            # Warm the prefix cache serially, then parallelise the rest.
            results = [run_probe(jobs[0][0][2], workdir)]
            with ThreadPoolExecutor(max_workers=args.workers) as pool:
                results += list(pool.map(lambda j: run_probe(j[0][2], workdir), jobs[1:]))

            for (q, rep), res in zip(jobs, results):
                records.append({"arm": arm, "qid": q[0], "bullet": q[1], "rep": rep,
                                "rubric": q[3], "text": res["text"],
                                "stopped": res["stopped"], "ms": res["ms"],
                                "usage": res["usage"], "model": res["model"]})
                print(f"  {q[0]:16s} rep{rep} {str(res['stopped']):18s} "
                      f"{len(res['text']):5d} chars {res['ms']:6d} ms", file=sys.stderr)

            log1 = len(rd(HOOK_LOG).splitlines()) if HOOK_LOG.exists() else 0
            print(f"  hook log +{log1 - log0} lines (control: the global file loaded here)",
                  file=sys.stderr)
    finally:
        shutil.copy2(backup, LIVE)
        back = sha(rd(LIVE))
        print(f"\n{'RESTORED OK' if back == live_sha else '!! RESTORE MISMATCH'}: "
              f"{LIVE} is {LIVE.stat().st_size} B, sha {back[:12]}", file=sys.stderr)

    # Judge with the global CLAUDE.md moved aside, so the judge's own disposition
    # cannot drift with the thing under test.
    print(f"\n{len(records)} responses. Judging on {JUDGE_MODEL}, one call each, "
          f"shuffled, global CLAUDE.md moved aside...", file=sys.stderr)
    aside = workdir / "CLAUDE.md.aside-for-judging"
    shutil.move(str(LIVE), str(aside))
    try:
        order = list(range(len(records)))
        random.Random(20260825).shuffle(order)
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            for i, v in zip(order, pool.map(
                    lambda i: judge(records[i]["text"], records[i]["rubric"],
                                    workdir, JUDGE_MODEL), order)):
                records[i].update(v)

        # Validate the cheap judge against the expensive one on a random sample.
        audit_idx = random.Random(9021).sample(order, min(AUDIT_SAMPLE, len(order)))
        print(f"auditing {len(audit_idx)} of {len(records)} on {AUDIT_MODEL}...",
              file=sys.stderr)
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            audits = list(pool.map(
                lambda i: judge(records[i]["text"], records[i]["rubric"],
                                workdir, AUDIT_MODEL), audit_idx))
        agree = 0
        for i, a in zip(audit_idx, audits):
            records[i]["audit_raised"] = a["raised"]
            agree += int(a["raised"] == records[i]["raised"])
        rate = agree / len(audit_idx) if audit_idx else 0.0
        print(f"judge agreement: {agree}/{len(audit_idx)} = {rate:.0%}", file=sys.stderr)
        if rate < 0.9:
            print("!! agreement below 90% -- the cheap judge is not good enough for this "
                  "measurement. Re-judge everything on the audit model before reading any "
                  "arm difference; low agreement is a fact about the JUDGE, not the split.",
                  file=sys.stderr)
    finally:
        shutil.move(str(aside), str(LIVE))
        fin = sha(rd(LIVE))
        print(f"{LIVE} restored, sha {fin[:12]} "
              f"({'matches original' if fin == live_sha else '!! MISMATCH'})", file=sys.stderr)

    wr(Path(args.out), json.dumps(records, indent=2))

    print("\n=== firing rate by arm ===", file=sys.stderr)
    print(f"{'query':18s} " + "".join(f"{a:>10s}" for a in arms), file=sys.stderr)
    for q in QUERIES:
        row = f"{q[0]:18s} "
        for arm in arms:
            cell = [r for r in records if r["arm"] == arm and r["qid"] == q[0]]
            hits = sum(1 for r in cell if r.get("raised") is True)
            row += f"{hits:>5d}/{len(cell):<4d}"
        print(row, file=sys.stderr)
    for arm in arms:
        cell = [r for r in records if r["arm"] == arm and "CONTROL" not in r["qid"]]
        hits = sum(1 for r in cell if r.get("raised") is True)
        print(f"arm {arm:9s} (probes only, control excluded): {hits}/{len(cell)}",
              file=sys.stderr)
    print(f"\nresults written to {args.out}", file=sys.stderr)
    print("Read against the module docstring before concluding anything.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
