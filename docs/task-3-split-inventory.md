# Task 3 inventory: the recognition/evidence split, per bullet

Working artifact for `durable-memory-model.md` §5 Task 3, step 1. Built **before** any bullet was
edited, per `refile-rules` §5 (*"Build the specifics inventory before changing a word"*).

**The bar this is checked against** (§5, extended by the spec's §3b): every item on the evidence
inventory is locatable **either** in the rewritten bullet **or** in the lesson file it points to, or
is named below as a deliberate drop with a reason. The split's premise is that no evidence item is
*dropped* — it is relocated behind a pointer — so a drop here is a defect to be justified, not a
feature.

**Scope boundary** (§5): this changes how much text a rule takes, never what it asserts. Each
bullet's after-text is checked in both directions — an assertion added, or one silently lost.

Source: `~/.claude/CLAUDE.md` §Verification → Validating the instrument, **10,858 B / 17 bullets** (14 top-level, 3 nested)
at the moment this ran `[measured 2026-08-25 with the section-extract awk in §0's next command]`.

Term meanings:

- **Recognition** — what makes you notice the rule applies, plus the action it demands. Stays in
  `CLAUDE.md`. Command names, flag names, the symptom, the instruction.
- **Evidence** — what makes you believe it. Dates, run IDs, measured numbers, the incident,
  the disconfirmed alternatives. Moves to `~/.claude/lessons/<slug>.md`.

---

## B1 — Citing a `file:line` as evidence means opening that file

**Recognition.** Citing a `file:line` as evidence; a grep hit proves the string exists, not that
anything runs it; **count occurrences rather than finding one**; an identifier appearing exactly
once in its file is a declaration nothing consumes.

**Evidence.** The dead `renderer: "svg"` literal; that it became a false claim in **both** a source
comment and a commit message.

**Slug.** `file-line-citation-must-be-opened`

---

## B2 — A code comment is a claim, not evidence

**Recognition.** A code comment is a claim, not evidence; quoting it into a doc launders it into
one; opening the file proves the comment exists, and that is not enough when the thing cited is
itself prose.

**Evidence.** `smoke-pages.mjs:246`; the phrase *"several pages contending for one `hugo server`'s
on-demand render"*; that the project CLAUDE.md repeated it and it was then used as a diagnosis;
both corrected 2026-08-23; the measurement that unseated it — concurrency 6 against 1 over 12
pages, navigation 1.34x, JS settle time 1.00x, all 12 reaching identical final DOM states.

**Slug.** `code-comment-is-not-evidence`

---

## B3 — A null result from an instrument you have not validated is not a result

**Recognition.** Null result; instrument you have not validated; before reporting "nothing fired",
or building on it, prove the probe can fire at all with a **positive control**; null results conceal
their own failure — a probe that never reached the code under test and a code path that never ran
are indistinguishable in the output.

**Evidence.** *None.* This bullet carries no date, no number, no incident. It is already pure
recognition.

**Disposition. Unchanged, byte for byte.** Recorded here because a split that touched every bullet
would be the tell that it was a rewrite pass wearing a split's clothes.

---

## B3a — The same applies to searches, in both directions

**Recognition.** Three ways a search yields a confident count that describes the search rather than
the code: (i) a pattern the shell mangled — the `$'…'` form survives as a bare argument but
collapses to the empty pattern, matching every line, once nested inside a command substitution in a
double-quoted string, and the tell is a count equal to the file's line total; (ii) a tool whose
domain silently excludes the target — `git grep` skips untracked files; (iii) a well-formed pattern
that cannot match a variant of the name it seeks — `lib-[a-z-]+\.html` cannot match `lib-d3.html`,
`arquero\.[a-f0-9]*\.js` cannot match `arquero.min.<hash>.js`. The third has no error to notice, so
prefer the shape that cannot have it: for "which members of set X are present", **enumerate what is
actually there and compare**, rather than grepping once per expected member. Also: count CR bytes
with `tr -dc` piped to `wc -c`, not with `grep`.

**Evidence.** `[verified 2026-08-19: the grep -c CR form returned 0 bare and 125 nested, on a
125-line file with zero CR bytes]`; `[verified 2026-08-21: the bare form returned 0 on a 69-line
CRLF file; od showed a CR on every line]`.

**Note on the boundary.** The two example regexes and the `git grep` fact are **recognition**, not
evidence: they are the shape you match a live pattern against while composing it, not the reason to
believe the rule. Kept inline deliberately.

**Slug.** `search-failures-that-look-like-results`

---

## B3b — "Unchanged" is a null result too, and the comparison is the instrument

**Recognition.** "Unchanged" is a null result; the comparison is the instrument; a prefix, a length,
or any field the encoding holds fixed reports "no change" against an artifact that did change;
**compare whole values, and on two known-different inputs first**; the mirror case — `git cherry`
compares patch-ids, so a commit reworked or squashed on its way in reads as unmerged though its
content is present; confirm with a content diff before calling a branch's work outstanding.

**Evidence.** The fixed-size QR GIF sharing its header, so a prefix check called a regenerated code
stale.

**Slug.** `unchanged-is-a-null-result`

---

## B3c — A no-op proof is scoped to the unit you compare

**Recognition.** A no-op proof is scoped to the unit you compare, not the change you meant to test;
strip-and-diff answers about the *file*, so a second change sharing it breaks the proof;
**compare the commit's parent tree to its staged tree**; a per-task commit split makes it exact for
free.

**Evidence.** The recorded pass *"strip every class attribute, all 7 files identical"* failing on
2 of 7, which also carry another task's `alt` additions.

**Slug.** `no-op-proof-scope`

---

## B4 — A check that only asks "did it succeed" passes on a degenerate result

**Recognition.** A check that only asks "did it succeed" passes on a degenerate result; **assert the
parsed value's type or shape, not that parsing returned**; `json.loads` hands back a `str` and
raises nothing for a document double-encoded as a JSON string literal; same shape for a 200 response
carrying an error page.

**Evidence.** *"the emitted JSON parses"* passing a whole site's JSON-LD that no consumer could
read `[2026-08-21]`; the pointer to the `feedback-verify-my-own-verification` memory in the
`EH-dataportal` project store.

**Slug.** `degenerate-pass-on-did-it-succeed`

---

## B5 — A line-oriented search assumes one record per line

**Recognition.** A line-oriented search assumes one record per line; when the thing being counted
can span lines the count is wrong and looks right; grepping for an opening `<img` and filtering out
`alt=` scores the opening line of every multi-line tag as a miss; distinct from the three search
failures above because the pattern is well-formed and does match; **count over parsed output —
built HTML through a DOM query or axe — rather than over source lines**.

**Evidence.** `[verified 2026-08-21: the sweep returns 16 on EH-dataportal's themes/dohmh/layouts
at HEAD and the true figure is 15 — one tag carried its alt two lines below the opening tag, and
the plan asserting 16 had run the same sweep]`.

**Slug.** `line-oriented-search-spans-records`

---

## B6 — A single-point reading cannot answer a question about change

**Recognition.** A single-point reading cannot answer a question about change; the two axes fail the
same way. *History:* to claim you introduced something, **compute the property on the base commit
too**; a current-state grep answers "does this exist", never "is this new". *Time:* one post-event
read cannot separate a fix that failed from a system that changed twice.

**Evidence.** Three of four duplicate top-level identifiers called mine predated the branch, and the
rename that justified would have left one of four inconsistent; sampling at +60ms and +660ms telling
a stale ARIA attribute from a listbox the library genuinely reopened.

**Slug.** `single-point-reading-cannot-show-change`

---

## B7 — A fixture field identical across every case it covers is dead, not passing

**Recognition.** A fixture field identical across every case it covers is dead, not passing; **diff
each field across a baseline's own cases before trusting it as a regression net**; one constant
everywhere is either constant by construction or reading a node that does not exist, and normalizing
`null` to the empty string disguises the second as the first; the sign narrows it for free — a
constant `true`, non-empty string, or count of 1 or more cannot come from a probe that found
nothing, so only a constant `0`/`false`/`null` needs an injection control.

**Evidence.** That narrowing cutting eleven always-identical fields to the three worth testing
`[2026-08-23]`; the "eighth shape" ordinal; the pointer to `feedback-verify-my-own-verification` in
the `EH-dataportal` store.

**Slug.** `constant-fixture-field-is-dead`

---

## B8 — A positive control rules out one explanation for a negative

**Recognition.** A positive control rules out **one** explanation for a negative — count the
explanations first; before reporting "it didn't load", "it didn't fire", "it isn't there", **list
every innocent reading that would look identical**; three explanations need three arms, not one
control; **factorize** — vary scope and the feature under test together, so each cell kills a
different confound.

**Evidence.** *"Does `~/.claude/rules/` honour `paths:`"* looking like one probe and being a 2x2 —
wrong frontmatter, an unread rules directory, and a dead hook all producing the same empty log; the
pointer to the `factorize-controls-for-a-negative-result` memory in the `claude-skills` store.

**Slug.** `count-the-explanations-for-a-negative`

---

## B9 — A positive control proves the probe can fire; it does not establish recall

**Recognition.** A positive control proves the probe can fire; it does not establish **recall**;
when the control instance is also the one whose vocabulary you wrote the probe from it is
**circular**, confirming only that the pattern matches the text it was derived from; to assert a
zero, **derive the probe's terms from the definition of what you are looking for rather than from
the hits you already have, or validate against a held-out instance**; cheap tell — count hits per
file, and if the file whose vocabulary you drew the pattern from holds an outsized share of them,
the probe is circular.

**Evidence.** The sweep for unsourced external claims validating itself on a dense cluster in
`site-wide` §12 and reporting zero across three other audit docs; a wider pattern finding them in
all three; the sweep having also missed four files outright while reporting a word count that
nearly matched.

**Slug.** `positive-control-does-not-establish-recall`

---

## B10 — In a two-arm comparison, perturb the variable under test

**Recognition.** In a two-arm comparison, **perturb the variable under test — never an input both
arms share**; perturbing the shared input moves both arms together, so the test passes whichever way
the mechanism works.

**Evidence.** The harness proving its probes by editing a committed baseline, and that injection
being unable to test the base-branch control job — the baseline being what both the head sweep and
the base run compare against, so both go red and the verdict reads "the data moved" when the truth
is that the baseline was edited; the discriminating arm needing the edit in the site source
instead `[2026-08-24]`.

**Slug.** `perturb-the-variable-not-the-shared-input`

---

## B11 — One probe's positive control does not validate the others in the same harness

**Recognition.** One probe's positive control does not validate the others in the same harness; a
control that fires proves *that* probe can fire, not that the sweep beside it ran to completion;
**any probe with a stop condition must emit why it stopped** — input exhausted, or its own guard
tripped — **and its count checked against an expectation derived independently**.

**Evidence.** A keyboard sweep ending at 20 of 128 stops while an axe control beside it fired
correctly; the "seventh shape" ordinal; the pointer to `feedback-verify-my-own-verification` in the
`EH-dataportal` store.

**Slug.** `one-probes-control-does-not-validate-others`

---

## B12 — A test run under conditions where the effect cannot occur is not evidence against it

**Recognition.** A test run under conditions where the effect cannot occur is not evidence against
it; a positive control proves the *instrument* can fire, not that the *conditions* could produce the
thing looked for; **before reporting a negative, state the conditions under which the effect would
appear and confirm the test met them**; for an intermittent effect, **agreement across N runs is
weak evidence at any N** — reproduce it on demand or argue from mechanism, and say which you are
doing.

**Evidence.** The in-flight-request check measured as "never binds" against a warm HTTP cache, where
the fetch resolves instantly and the check has no window in which to bind — establishing the check
inert *when cached*, saying nothing about the cold case the theory was about, and being written into
the code as a disproof anyway `[2026-08-23]`; the same session calling a capture race absent three
separate times on agreeing runs.

**Slug.** `conditions-must-allow-the-effect`

---

## B13 — An eval or test prompt must not hand over the facts the thing under test must go find

**Recognition.** An eval or test prompt must not hand over the facts the thing under test is
supposed to go find; a prompt that narrates the session back to the agent **scores identically for a
model that read the transcript and one that didn't**; the grounding step it was meant to exercise
becomes invisible; **put required prior state in the expected output as a precondition, not in the
user's mouth**.

**Evidence.** *None.* No date, no number, no named incident — the failure is stated as a mechanism.

**Disposition. Unchanged, byte for byte.**

---

## B14 — Before deleting content as "already covered elsewhere", verify the claim survives

**Recognition.** Before deleting content as "already covered elsewhere", verify the **claim**
survives, not the keyword; a grep proving the term appears does not prove the surviving copy asserts
the same thing, and the copy you are deleting may be the newer one; applies to memory hooks,
duplicate doc sections, consolidating audit findings; **when moving or splitting a document, check
claim by claim, not section by section** — dropping content because its *category* is covered
elsewhere is what makes a move lossy, and the loss is invisible in the diff.

**Evidence.** *None.* No date, no number, no named incident.

**Disposition. Unchanged, byte for byte.**

---

## Roll-up

| Bullet | Evidence items | Disposition |
|---|---:|---|
| B1 | 2 | split |
| B2 | 6 | split |
| B3 | 0 | **unchanged** |
| B3a | 2 | split |
| B3b | 1 | split |
| B3c | 1 | split |
| B4 | 2 | split |
| B5 | 1 | split |
| B6 | 2 | split |
| B7 | 3 | split |
| B8 | 2 | split |
| B9 | 3 | split |
| B10 | 1 | split |
| B11 | 3 | split |
| B12 | 2 | split |
| B13 | 0 | **unchanged** |
| B14 | 0 | **unchanged** |

**14 of 17 bullets split; 3 carry no evidence specifics at all and are kept byte for byte.**

That three of seventeen are already in the target form is the first quantitative thing this task
learned, and it bounds the yield: the split has less to do than the section's size suggests,
because the section's size is not uniformly evidence.
