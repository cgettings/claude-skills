#!/usr/bin/env python3
"""Route (a)'s screen: are ANY bullets in the pilot section load-bearing?

docs/durable-memory-model.md SS5 Task 3, step 5 redesign.

WHY THIS EXISTS. The 2026-08-29 probe returned A~=B~=C -- 30/30 raised on every
arm including the one with the section DELETED. The rules were never supplying
the answers, so no arm could differ. Before spending another ~$3 on a three-arm
run, find out whether any query in this section can discriminate at all.

DESIGN. Two phases, cheapest first.

  Phase 1  arm C (section deleted), every candidate, 2 repeats.
           A candidate SURVIVES if the model does NOT raise the point.
  Phase 2  arm A (live file, section present), survivors only, 2 repeats.
           A survivor is CONFIRMED if the model DOES raise the point.

Phase 2 is not optional bookkeeping. A phase-1 survival has two innocent
readings -- the rule is load-bearing, or the query is too vague to engage --
and they are indistinguishable in phase 1's output. Only arm A separates them.
That is this section's own rule about counting the explanations for a negative,
applied to the instrument that tests it.

PRE-REGISTERED READING RULE (written before the run; do not amend afterwards).

  raised            judge returns true
  hole              judge returned no parseable JSON. Reported SEPARATELY and
                    never folded into a rate -- the 2026-08-29 audit gate
                    scored None != True as a disagreement and tripped at a
                    spurious 60%.
  survivor          raised 0/2 on arm C, with no holes
  confirmed         survivor raised 2/2 on arm A
  bad query         survivor raised 0/2 on arm A -- the query, not the rule

  >=3 confirmed  a discriminating probe exists; build (a)+(b) on that sample
   0 confirmed   the firing claim is unfalsifiable on this section; route (c)
  1-2 confirmed  underpowered; report and decide, do not proceed silently

  NO POWER: zero survivors in phase 1 means the screen reproduced the
  2026-08-29 ceiling at n=8 rather than n=5. That is a real answer -- route
  (c) -- not a licence to write more queries in the same shape.

Candidates target bullets that are LOCAL and NON-OBVIOUS: named tool
behaviour, a threshold from one incident, a trap with no general-competence
route to it. That is the sample the old probe lacked. No query uses its own
rule's vocabulary.

RESULT, 2026-09-01 -- appended after the run. The rule above is UNAMENDED.

  8 candidates: 5 saturated on arm C, 3 came back 0/2 there and 2/2 on arm A,
  and the script printed "3 confirmed -- a discriminating probe exists".

  THAT COUNT IS RETRACTED, same day, by probe-confirmed-queries.py. Re-running
  arm C on the same three gave 1/2, 1/2, 0/2. Arm C is a low NONZERO rate, so
  a 0/2 screen at 2 repeats fires 56% of the time against a true rate of 0.25
  -- three survivors out of eight is close to what screening saturated bullets
  produces on its own. THE TWO-REPEAT SCREEN CANNOT SELECT QUERIES. Raise
  REPEATS well above 2 before trusting a survivor, or read a 0/N as a coin
  flip. The procedure (arm C filter, then arm A confirmation) is sound; the
  resolution was not.

MUTATES ~/.claude/CLAUDE.md in place during phase 1 and restores it in a
finally, verifying by sha256. Read RESTORED OK / !! RESTORE MISMATCH.
"""
import hashlib
import json
import os
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

STRIP_ENV = {"CLAUDECODE", "ANTHROPIC_LOG", "ANTHROPIC_BASE_URL",
             "HTTPS_PROXY", "https_proxy"}
PROBE_MODEL = "claude-sonnet-5"
JUDGE_MODEL = "claude-haiku-4-5"
REPEATS = 2
WORKERS = 3

SUFFIX = ("\n\nAnswer in prose in this turn. Do not use tools and do not ask "
          "clarifying questions -- give your actual assessment.")

# (id, bullet, query, rubric)
CANDIDATES = [
    ("S1-B5", "'Unchanged' is a null result too / git cherry compares patch-ids",
     "I merged a feature branch into main last week, but a couple of those commits got "
     "reworked and squashed during review on the way in. Now `git cherry main feature` "
     "lists three commits as still outstanding. I'm going to re-apply those three so "
     "nothing gets lost -- sound?",
     "Identifies that `git cherry` compares patch-ids, so a commit reworked or squashed on "
     "its way in reads as unmerged even though its content is already present -- and that "
     "re-applying would duplicate it. Credit checking tree identity instead (e.g. "
     "`git merge-tree --write-tree`, or diffing the trees), or any statement that a commit "
     "LIST is the wrong instrument for the question 'is this content present'."),

    ("S2-B4", "the corpus records your own query",
     "I grepped our agent's debug log for eight different config field names to find out "
     "which ones the runtime actually touches. Every single one came back with exactly one "
     "hit. So each field is used exactly once at startup -- I'm writing that up.",
     "Points out that the log records the searcher's OWN commands or queries, so the sweep "
     "is finding its own probe rather than runtime behaviour -- and that a count equal to "
     "the number of terms typed is the tell, with the true count possibly zero. Credit "
     "'strip your own tool-input / echo lines before counting' or 'you are matching your "
     "own search'."),

    ("S3-B12", "a blind spot explains missed cases only if something falls through it",
     "Our event classifier left 9 events unlabelled. Digging in, I found it's completely "
     "blind to two marker types that definitely occur in the data. That explains the 9 -- "
     "I'll write the blind spot up as the cause and move on.",
     "Says the set difference must be MEASURED before the blind spot is reported as the "
     "cause -- the markers it cannot see may contribute zero, being co-extensive with ones "
     "it already sees, or sitting on records that carry no marker at all. Credit "
     "'quantify the overlap first' or 'check that the unclassified events are actually the "
     "ones carrying those markers'."),

    ("S4-B15", "a precondition check that reads the same field the measurement reads",
     "To test whether a long-running session had gone stale, I first confirmed it still had "
     "the document loaded by asking it to quote one specific sentence back to me. Then I "
     "deleted that sentence from the file and asked again. It quoted the sentence again, so "
     "the session is definitely holding stale context.",
     "Identifies that the precondition check PUT the sentence into the session's own "
     "history, contaminating the later measurement -- so quoting it afterwards no longer "
     "proves stale context, and that half of the test is dead on arrival. Credit "
     "'verify the precondition on a different instance than the one you perturb' or "
     "'you have already handed it the answer'."),

    ("S5-B17", "a trigger that also moves something the classifier already explains",
     "I want to know whether switching permission mode causes the session cache to rebuild. "
     "My classifier already filters out rebuilds caused by effort-level changes, so those "
     "won't confuse things. Plan is to toggle plan mode a few times and read whatever "
     "events are left over.",
     "Warns that the trigger may ALSO move a field the classifier already strips -- "
     "entering plan mode can change the model or the effort level -- which makes those "
     "boundaries VOID, carrying no information rather than noisy information. Credit "
     "'name every covariate the trigger could move and read them on the FIRST boundary' or "
     "'those turns will tell you nothing by construction'."),

    ("S6-B16", "perturb the variable under test, never an input both arms share",
     "I have a head job and a base-branch control job, and both compare their output "
     "against the same committed baseline file. To prove the check can actually fail, I "
     "edited that baseline file and confirmed both jobs went red. Positive control done.",
     "Identifies that the injection moved an input BOTH arms share, so they move together "
     "and the test passes whichever way the mechanism works -- it cannot validate the "
     "base-branch control at all. Credit 'perturb the variable under test (the source), "
     "not the shared baseline' or 'both going red is what you would see either way'."),

    ("S7-B18", "one probe's positive control does not validate the others",
     "Our accessibility harness runs two sweeps over the site. I injected a fault into the "
     "colour-contrast sweep and it caught it, so the harness is validated. The keyboard "
     "sweep came back reporting 20 stops and no issues, which is great.",
     "Says a control proving ONE probe can fire establishes nothing about whether the other "
     "sweep ran to completion, and that the keyboard sweep's count of 20 needs an "
     "independently derived expectation and a reason it stopped. Credit '20 out of how "
     "many?' or 'each probe needs its own control / must emit why it stopped'."),

    ("S8-B6", "a no-op proof is scoped to the unit you compare",
     "My refactor should be a pure no-op for rendered output. I stripped every `class=` "
     "attribute out of the 7 files I touched and diffed them against the originals -- all "
     "7 came back identical. That's the no-op proved.",
     "Points out that strip-and-diff answers about the whole FILE, so any second change "
     "sharing those files breaks the proof -- it can mask the change or be masked by it. "
     "Credit 'compare the commit's parent tree to its staged tree' or 'another edit in the "
     "same file invalidates this comparison'."),
]


def rd(p):
    with open(p, "r", encoding="utf-8", newline="") as fh:
        return fh.read()


def wr(p, t):
    with open(p, "w", encoding="utf-8", newline="") as fh:
        fh.write(t)


def sha(t):
    return hashlib.sha256(t.encode("utf-8")).hexdigest()


def claude(prompt, cwd, model=None, timeout=240):
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


def run_probe(query, cwd, timeout=240):
    env = {k: v for k, v in os.environ.items() if k not in STRIP_ENV}
    proc = subprocess.Popen(
        ["claude", "-p", query + SUFFIX, "--model", PROBE_MODEL,
         "--output-format", "stream-json", "--verbose", "--include-partial-messages"],
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


def judge(response, rubric, cwd):
    prompt = (
        "You are scoring one response from a controlled experiment. You do not know which "
        "condition produced it, and must not guess.\n\n"
        "Score ONLY this: does the response raise the specific methodological point below, "
        "on its own, as something that matters here?\n\n"
        f"THE POINT:\n{rubric}\n\n"
        "Credit it if the substance is present in any wording. Do NOT credit generic caution "
        "('be careful', 'consider testing more', 'double-check') that does not contain the "
        "specific point. Do NOT credit the response merely doing what was asked well.\n\n"
        "--- RESPONSE UNDER TEST ---\n"
        f"{response}\n"
        "--- END RESPONSE ---\n\n"
        "Reply with exactly one line of JSON and nothing else:\n"
        '{"raised": true, "quote": "<=25 words from the response"}'
    )
    txt = claude(prompt, cwd, model=JUDGE_MODEL)
    s, e = txt.find("{"), txt.rfind("}")
    if s != -1 and e > s:
        try:
            d = json.loads(txt[s:e + 1])
            return {"raised": bool(d.get("raised")), "quote": str(d.get("quote", ""))[:200]}
        except json.JSONDecodeError:
            pass
    return {"raised": None, "quote": "", "judge_raw": txt[:200]}


def leg(label, cands, cwd, records):
    jobs = [(c, r) for c in cands for r in range(REPEATS)]
    print(f"\n=== {label}: {len(jobs)} responses on {PROBE_MODEL} ===", file=sys.stderr)
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = {ex.submit(run_probe, c[2], cwd): (c, r) for c, r in jobs}
        for f, (c, r) in futs.items():
            res = f.result()
            j = judge(res["text"], c[3], cwd)
            records.append({"leg": label, "id": c[0], "bullet": c[1], "repeat": r,
                            "raised": j["raised"], "quote": j.get("quote", ""),
                            "chars": len(res["text"]), "stopped": res["stopped"],
                            "model": res["model"], "ms": res["ms"],
                            "usage": res["usage"], "text": res["text"]})
            print(f"  {label} {c[0]:9s} r{r}  raised={str(j['raised']):5s} "
                  f"{len(res['text']):5d} chars {res['ms']:6d} ms", file=sys.stderr)
    return records


def tally(records, label, cands):
    out = {}
    for c in cands:
        rs = [r["raised"] for r in records if r["leg"] == label and r["id"] == c[0]]
        out[c[0]] = {"raised": sum(1 for x in rs if x is True),
                     "not_raised": sum(1 for x in rs if x is False),
                     "holes": sum(1 for x in rs if x is None), "n": len(rs)}
    return out


def main():
    workdir = ROOT / ".task3-probe"
    workdir.mkdir(parents=True, exist_ok=True)
    live, before = rd(LIVE), rd(BEFORE)
    if live.count(before) != 1:
        raise SystemExit(
            f"pilot section appears {live.count(before)}x in {LIVE}, expected exactly 1.\n"
            "Re-cut docs/task-3-section-before.md before running.")
    backup = workdir / "CLAUDE.md.screen-backup"
    shutil.copy2(LIVE, backup)
    live_sha = sha(live)
    arm_c = live.replace(before, "")
    wr(workdir / "arm-C_absent.md", arm_c)
    print(f"live {LIVE.stat().st_size} B sha {live_sha[:12]}; "
          f"arm C {len(arm_c.encode('utf-8'))} B", file=sys.stderr)

    records = []
    try:
        wr(LIVE, arm_c)
        leg("C_absent", CANDIDATES, ROOT, records)
    finally:
        shutil.copy2(backup, LIVE)
        ok = sha(rd(LIVE)) == live_sha
        print("RESTORED OK" if ok else "!! RESTORE MISMATCH", file=sys.stderr)
        if not ok:
            with open(ROOT / "docs" / "task-3-screen-results.json", "w",
                      encoding="utf-8", newline="") as fh:
                json.dump({"records": records}, fh, indent=2)
            return 2

    t_c = tally(records, "C_absent", CANDIDATES)
    survivors = [c for c in CANDIDATES
                 if t_c[c[0]]["raised"] == 0 and t_c[c[0]]["holes"] == 0]
    print(f"\nphase 1: {len(survivors)} survivors of {len(CANDIDATES)}", file=sys.stderr)

    t_a = {}
    if survivors:
        # The live file is already restored to arm A, so phase 2 needs no swap.
        leg("A_full", survivors, ROOT, records)
        t_a = tally(records, "A_full", survivors)

    confirmed = [c for c in survivors if t_a.get(c[0], {}).get("raised") == REPEATS]
    bad = [c for c in survivors if t_a.get(c[0], {}).get("raised") == 0]

    print("\n" + "=" * 74)
    print(f"{'id':10s} {'C raised':>9s} {'A raised':>9s}  verdict")
    for c in CANDIDATES:
        a = t_a.get(c[0])
        av = f"{a['raised']}/{a['n']}" if a else "-"
        if c in confirmed:
            v = "CONFIRMED -- discriminates"
        elif c in bad:
            v = "bad query (fails with the rule too)"
        elif c in survivors:
            v = "partial on A -- inconclusive"
        elif t_c[c[0]]["holes"]:
            # NOT saturated. A hole is an unscored response, and the survivor
            # filter excludes it -- so the else branch below would assert the
            # opposite of what happened. This branch exists because it did:
            # S5-B17 scored False + hole on arm C and printed as "saturated".
            v = f"UNSCORED -- {t_c[c[0]]['holes']} judge hole(s); re-judge before reading"
        else:
            v = "saturated (raised without the rule)"
        cc = f"{t_c[c[0]]['raised']}/{t_c[c[0]]['n']}"
        print(f"{c[0]:10s} {cc:>9s} {av:>9s}  {v}")
    holes = sum(1 for r in records if r["raised"] is None)
    print(f"\nholes (judge returned no JSON): {holes} -- reported separately, not scored")
    print(f"survivors {len(survivors)}/{len(CANDIDATES)}, confirmed {len(confirmed)}")
    if len(confirmed) >= 3:
        print("VERDICT: >=3 confirmed -- a discriminating probe exists; build (a)+(b) on these")
    elif len(confirmed) == 0:
        print("VERDICT: 0 confirmed -- firing claim unfalsifiable on this section; route (c)")
    else:
        print(f"VERDICT: {len(confirmed)} confirmed -- underpowered; report and decide")

    out = ROOT / "docs" / "task-3-screen-results.json"
    with open(out, "w", encoding="utf-8", newline="") as fh:
        json.dump({"records": records, "phase1": t_c, "phase2": t_a,
                   "survivors": [c[0] for c in survivors],
                   "confirmed": [c[0] for c in confirmed]}, fh, indent=2)
    print(f"\nwrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
