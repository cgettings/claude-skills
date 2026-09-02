#!/bin/sh
# Report every always-loaded instruction file against its budget.
#
# Two different kinds of limit are checked here, and not conflating them is most of the
# point — they have different consequences and different fixes:
#
#   CEILING     a number we chose (docs/durable-memory-model.md §3c). Passing it costs
#               tokens in every session of every day, and means the next addition should
#               route something out rather than append. Nothing breaks.
#   TRUNCATION  a platform limit (§2). MEMORY.md loads only its first 200 lines OR the
#               first 25,000 B, whichever arrives first. Passing it means the tail
#               silently stops loading while the file on disk still looks complete.
#
# Which of MEMORY.md's two truncation caps binds depends on the file's bytes-per-line,
# and for prose index files it is never the line count: at ~178 B/line, 25,000 B arrives
# around line 140. "Under 200 lines" is therefore not evidence of anything, which is why
# the report prints the line the byte cap actually lands on instead of a line count.
#
# Reports on the CURRENT DIRECTORY's project, not on the repo this script lives in, so
# it can be run from any worktree. The project ceiling is per-branch (§3c) — the same
# file differs across worktrees, and the branch that most needs a ceiling is the one
# nobody currently has open — so the project row names the branch it measured.
#
#   sh scripts/check-memory-budget.sh   ; echo $?   # 0 = all under, 1 = at least one over
#
# Chain it with `;` rather than `&&`: a non-zero exit is the informative answer here.

# From §3c. Chosen, not derived — no measurement establishes 25,000 over 30,000. They are
# revised against what a split actually yields, not defended.
CEILING_GLOBAL=25000
CEILING_PROJECT=20000
CEILING_MEMORY=20000

# From §2, and these are the platform's, not ours.
TRUNC_BYTES=25000
TRUNC_LINES=200

over=0
checked=0
total=0

# wc -l counts newlines, so a file with no trailing newline reports one line short.
# awk END{NR} counts records, which is the number wanted here.
lines_of() { awk 'END { print NR }' "$1"; }

report() {
    label=$1
    path=$2
    ceiling=$3

    if [ ! -f "$path" ]; then
        printf '  %-34s %9s  %8d  not present\n' "$label" "-" "$ceiling"
        return
    fi

    bytes=$(wc -c < "$path" | tr -d ' ')
    checked=$((checked + 1))
    total=$((total + bytes))

    pct=$(awk -v b="$bytes" -v c="$ceiling" 'BEGIN { printf "%d", (b * 100) / c }')
    if [ "$bytes" -gt "$ceiling" ]; then
        over=$((over + 1))
        printf '  %-34s %9d  %8d  OVER by %d B (%d%%)\n' \
            "$label" "$bytes" "$ceiling" "$((bytes - ceiling))" "$pct"
    else
        printf '  %-34s %9d  %8d  ok (%d%%, %d B headroom)\n' \
            "$label" "$bytes" "$ceiling" "$pct" "$((ceiling - bytes))"
    fi
}

echo "always-loaded instruction files, measured $(date -u +%Y-%m-%d)"
printf '  %-34s %9s  %8s  %s\n' "file" "bytes" "ceiling" "status"

# 1. The global file: one copy, loaded into every session in every project.
report "~/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" "$CEILING_GLOBAL"

# 2. The project file, named with its branch. Run it, never read it from a cached
#    status block — a session-start snapshot goes stale the moment anyone switches.
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || branch=""
[ -n "$branch" ] || branch="no branch"
report "./CLAUDE.md ($branch)" "./CLAUDE.md" "$CEILING_PROJECT"

# 3. MEMORY.md, in the per-directory store. The store's name is the absolute path with
#    ':', '/' AND '.' all folded to '-' -- the dot matters and is easy to miss, because
#    the sibling-worktree convention puts one in the path: EH-dataportal.worktrees
#    resolves to a store named ...-EH-dataportal-worktrees-..., so a fold that handles
#    only ':' and '/' silently reports "no project store" for every worktree. The drive
#    letter's case varies between stores that already exist, so match case-insensitively
#    rather than assuming either spelling.
here=$(pwd -W 2>/dev/null || pwd)
want=$(printf '%s' "$here" | tr ':/.' '---' | tr 'A-Z' 'a-z')
store=""
for d in "$HOME"/.claude/projects/*/; do
    [ -d "$d" ] || continue
    if [ "$(basename "$d" | tr 'A-Z' 'a-z')" = "$want" ]; then
        store=$d
        break
    fi
done

if [ -z "$store" ]; then
    printf '  %-34s %9s  %8d  no project store for this directory\n' \
        "MEMORY.md" "-" "$CEILING_MEMORY"
else
    mem="${store}memory/MEMORY.md"
    report "MEMORY.md" "$mem" "$CEILING_MEMORY"

    # The truncation report, which is the part a ceiling check would otherwise miss.
    if [ -f "$mem" ]; then
        mb=$(wc -c < "$mem" | tr -d ' ')
        ml=$(lines_of "$mem")
        awk -v b="$mb" -v n="$ml" -v tb="$TRUNC_BYTES" -v tl="$TRUNC_LINES" 'BEGIN {
            bpl = (n > 0) ? b / n : 0
            at  = (bpl > 0) ? int(tb / bpl) : 0
            printf "    truncation: %d B over %d lines = %.0f B/line; ", b, n, bpl
            if (b > tb)
                printf "ALREADY PAST %d B - the tail is not loading\n", tb
            else if (n > tl)
                printf "ALREADY PAST %d lines - the tail is not loading\n", tl
            else if (at <= tl)
                printf "%d B arrives at ~line %d, so the byte cap binds first\n", tb, at
            else
                printf "the %d-line cap binds first, at ~%d B\n", tl, int(bpl * tl)
        }'
        # Count a live truncation as a failure: silent data loss outranks a budget choice.
        # Only when `report` has not already counted this same file, though. TRUNC_BYTES
        # sits above CEILING_MEMORY, so every byte-cap truncation is also a ceiling
        # breach, and counting both makes one file read as "2 over budget".
        if [ "$mb" -le "$CEILING_MEMORY" ]; then
            if [ "$mb" -gt "$TRUNC_BYTES" ] || [ "$ml" -gt "$TRUNC_LINES" ]; then
                over=$((over + 1))
            fi
        fi
    fi
fi

# Emit the counts unconditionally: a run that measured nothing must not read as a pass.
if [ "$checked" -eq 0 ]; then
    echo "measured 0 files - no always-loaded file found from $(pwd)"
    exit 2
fi

printf 'measured %d files, %d B always loaded here: ' "$checked" "$total"
if [ "$over" -eq 0 ]; then
    echo "all under budget"
    exit 0
fi
echo "$over over budget"
exit 1
