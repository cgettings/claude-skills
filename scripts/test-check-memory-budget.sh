#!/bin/sh
# Fault-injection test for check-memory-budget.sh.
#
# Run in the environment as it stands, that script prints one OVER row and four "ok"s.
# An "ok" that has never been anything else is not a pass — it is a field that cannot
# vary, and the same output would come back from a report that never opened the file.
# Every branch below is therefore driven to BOTH states, and the exit code is checked
# alongside the text: a script that prints the right words and exits 0 anyway is worse
# than one that prints nothing.
#
# HOME is redirected to a fixture so the global file and the project store are both
# under the test's control. That is what makes an all-under arm reachable at all — with
# the real HOME the global file is 227% over and exit 0 can never occur, so the pass
# path would be permanently unexercised.
#
#   sh scripts/test-check-memory-budget.sh   ; echo $?   # 0 = every arm behaved

SCRIPT=$(cd "$(dirname "$0")" && pwd)/check-memory-budget.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

pass=0
fail=0

# Build a fixture HOME plus a working directory, with sizes given per arm.
# $1 global bytes, $2 project bytes, $3 MEMORY.md bytes, $4 MEMORY.md lines
setup() {
    rm -rf "$tmp/home" "$tmp/work"
    mkdir -p "$tmp/home/.claude" "$tmp/work"

    [ "$1" = "none" ] || awk -v n="$1" 'BEGIN { while (length(s) < n) s = s "x"; print substr(s, 1, n - 1) }' > "$tmp/home/.claude/CLAUDE.md"
    [ "$2" = "none" ] || awk -v n="$2" 'BEGIN { while (length(s) < n) s = s "y"; print substr(s, 1, n - 1) }' > "$tmp/work/CLAUDE.md"

    if [ "$3" != "none" ]; then
        win=$(cd "$tmp/work" && (pwd -W 2>/dev/null || pwd))
        store=$(printf '%s' "$win" | tr ':/.' '---' | tr 'A-Z' 'a-z')
        mkdir -p "$tmp/home/.claude/projects/$store/memory"
        awk -v n="$3" -v l="$4" 'BEGIN {
            per = int(n / l)
            for (i = 1; i <= l; i++) { s = ""; while (length(s) < per - 1) s = s "z"; print s }
        }' > "$tmp/home/.claude/projects/$store/memory/MEMORY.md"
    fi
}

# $1 arm name, $2 expected exit, $3 pattern that must appear in the output
arm() {
    name=$1
    want_exit=$2
    want_text=$3
    out=$(cd "$tmp/work" && HOME="$tmp/home" sh "$SCRIPT" 2>&1)
    got_exit=$?

    ok=1
    [ "$got_exit" = "$want_exit" ] || ok=0
    printf '%s' "$out" | grep -q "$want_text" || ok=0

    if [ "$ok" = 1 ]; then
        printf '  PASS  %-38s exit %s, matched: %s\n' "$name" "$got_exit" "$want_text"
        pass=$((pass + 1))
    else
        printf '  FAIL  %-38s exit %s (wanted %s), looking for: %s\n' \
            "$name" "$got_exit" "$want_exit" "$want_text"
        printf '%s\n' "$out" | sed 's/^/          /'
        fail=$((fail + 1))
    fi
}

echo "fault injection against $SCRIPT"

# The negative control, and the reason HOME is redirected: prove exit 0 is reachable.
# Without this arm every other arm's non-zero exit could come from a script that always
# fails, and all six would still look like they had caught their fault.
setup 5000 5000 5000 20
arm "all under budget" 0 "all under budget"

setup 30000 5000 5000 20
arm "global over ceiling" 1 "OVER by 5000 B"

setup 5000 25000 5000 20
arm "project over ceiling" 1 "OVER by 5000 B"

setup 5000 5000 22000 20
arm "MEMORY.md over ceiling, not truncated" 1 "OVER by 2000 B"

# Truncation is a different failure from a ceiling: the file is silently half-loaded.
# 30,000 B is past the byte cap; 240 short lines are past the line cap while well under it.
setup 5000 5000 30000 20
arm "MEMORY.md past the 25,000 B cap" 1 "ALREADY PAST 25000 B"

setup 5000 5000 4800 240
arm "MEMORY.md past the 200-line cap" 1 "ALREADY PAST 200 lines"

# Which cap binds is the report's own claim, so check it flips with bytes-per-line.
# Under both the ceiling and the caps, so exit 0 is correct here -- this arm checks
# only which cap the report names. 475 B/line puts 25,000 B at line 52, far inside 200.
setup 5000 5000 19000 40
arm "dense file: byte cap binds first" 0 "byte cap binds first"

setup 5000 5000 3000 150
arm "sparse file: line cap binds first" 0 "line cap binds first"

# Absences must be reported, never silently skipped.
# A path with a dot in it. The first ten arms all passed while the store lookup was
# broken for every worktree, because mktemp never produces a dotted path -- the arms
# were real but the sample was not.
mkdir -p "$tmp/work.worktrees"
setup_dotted() {
    rm -rf "$tmp/home" "$tmp/work.worktrees/wt"
    mkdir -p "$tmp/home/.claude" "$tmp/work.worktrees/wt"
    awk 'BEGIN { print "x" }' > "$tmp/home/.claude/CLAUDE.md"
    win=$(cd "$tmp/work.worktrees/wt" && (pwd -W 2>/dev/null || pwd))
    store=$(printf '%s' "$win" | tr ':/.' '---' | tr 'A-Z' 'a-z')
    mkdir -p "$tmp/home/.claude/projects/$store/memory"
    awk 'BEGIN { for (i = 1; i <= 10; i++) print "zzzz" }' > "$tmp/home/.claude/projects/$store/memory/MEMORY.md"
}
setup_dotted
out=$(cd "$tmp/work.worktrees/wt" && HOME="$tmp/home" sh "$SCRIPT" 2>&1)
if printf '%s' "$out" | grep -q "truncation:"; then
    printf '  PASS  %-38s store found under a dotted path
' "dotted path resolves its store"
    pass=$((pass + 1))
else
    printf '  FAIL  %-38s store NOT found under a dotted path
' "dotted path resolves its store"
    printf '%s
' "$out" | sed 's/^/          /'
    fail=$((fail + 1))
fi

setup 5000 5000 none 0
arm "no project store" 0 "no project store"

setup none none none 0
arm "nothing to measure exits 2" 2 "measured 0 files"

printf 'arms: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
