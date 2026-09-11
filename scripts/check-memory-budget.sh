#!/bin/sh
# Report every always-loaded instruction file against its budget.
#
# Two different kinds of limit are checked here, and not conflating them is most of the
# point — they have different consequences and different fixes:
#
#   CEILING     a number we chose (docs/durable-memory-model.md §3c). Passing it costs
#               tokens in every session of every day. Nothing breaks, and nothing is
#               owed: a ceiling is a reading, never a reason to route an entry somewhere
#               it does not belong `[2026-09-09, restated 2026-09-10: "i don't want the
#               ceilings to dictate structural moves or changes"]`. Adding a rule to a
#               CLAUDE.md that is already over is fine.
#   TRUNCATION  a platform limit (§2). MEMORY.md loads only its first 200 lines OR the
#               first 25,000 B, whichever arrives first. Passing it means the tail
#               silently stops loading while the file on disk still looks complete.
#               This is the only limit here that should change anyone's handling of an
#               entry, and `--memory-only` reports it alone.
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
#   sh scripts/check-memory-budget.sh --memory-only ; echo $?   # MEMORY.md vs the caps
#
# Chain it with `;` rather than `&&`: a non-zero exit is the informative answer here.
#
# An unrecognised argument exits 2 rather than falling back to the full report: a caller
# that asked for the narrow reading must not silently get the wide one.

memory_only=0
for a in "$@"; do
    case "$a" in
        --memory-only) memory_only=1 ;;
        -h|--help)
            sed -n '2,/^$/p' "$0"
            exit 0
            ;;
        *)
            echo "check-memory-budget.sh: unknown argument '$a'" >&2
            echo "usage: check-memory-budget.sh [--memory-only]" >&2
            exit 2
            ;;
    esac
done

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

if [ "$memory_only" -eq 1 ]; then
    # The limit column is the platform's byte cap in this mode, not a chosen ceiling —
    # the two are different numbers and labelling them alike is what makes a ceiling
    # read as though it bound something.
    mem_limit=$TRUNC_BYTES
    echo "MEMORY.md against the platform cap, measured $(date -u +%Y-%m-%d)"
    printf '  %-34s %9s  %8s  %s\n' "file" "bytes" "cap" "status"
else
    mem_limit=$CEILING_MEMORY
    echo "always-loaded instruction files, measured $(date -u +%Y-%m-%d)"
    printf '  %-34s %9s  %8s  %s\n' "file" "bytes" "ceiling" "status"

    # 1. The global file: one copy, loaded into every session in every project.
    report "~/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" "$CEILING_GLOBAL"

    # 2. The project file, named with its branch. Run it, never read it from a cached
    #    status block — a session-start snapshot goes stale the moment anyone switches.
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || branch=""
    [ -n "$branch" ] || branch="no branch"
    report "./CLAUDE.md ($branch)" "./CLAUDE.md" "$CEILING_PROJECT"
fi

# 3. MEMORY.md, in the per-directory store. The store's name is the absolute path with
#    ':', '/' AND '.' all folded to '-' -- the dot matters and is easy to miss, because
#    the sibling-worktree convention puts one in the path: EH-dataportal.worktrees
#    resolves to a store named ...-EH-dataportal-worktrees-..., so a fold that handles
#    only ':' and '/' silently reports "no project store" for every worktree. The drive
#    letter's case varies between stores that already exist, so match case-insensitively
#    rather than assuming either spelling.
# 3a. `autoMemoryDirectory` overrides the path-folded store, and a git worktree is
#     exactly where it usually does: Claude Code gives each worktree its own store and
#     leaves the memory dir out of it, so the convention is to repoint the setting at
#     the main checkout's. Folding the path alone therefore finds a store, looks for a
#     MEMORY.md that was never there, and reports "not present" -- a null that reads
#     like a result, on the one limit here that is the platform's rather than ours
#     `[2026-09-09: reported "not present" from an EH-dataportal worktree while the
#     live file sat at 13,818 B of a 25,000 B cap, unwatched]`.
#
#     Most-specific settings file wins. That order is taken from the file names rather
#     than verified against Claude Code's docs; in practice only one file sets the key.
mem=""
mem_src=""
for s in ".claude/settings.local.json" ".claude/settings.json" "$HOME/.claude/settings.json"; do
    [ -f "$s" ] || continue
    v=$(sed -n 's/.*"autoMemoryDirectory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$s" | head -1)
    [ -n "$v" ] || continue
    # Quote the '~/' in the strip pattern: unquoted, bash tilde-expands the word first,
    # so the pattern becomes $HOME/, matches nothing, and the '~' survives into the path.
    case "$v" in "~/"*) v="$HOME/${v#'~/'}" ;; esac
    mem="$v/MEMORY.md"
    mem_src="$s"
    break
done

if [ -z "$mem" ]; then
    here=$(pwd -W 2>/dev/null || pwd)
    want=$(printf '%s' "$here" | tr ':/.' '---' | tr 'A-Z' 'a-z')
    for d in "$HOME"/.claude/projects/*/; do
        [ -d "$d" ] || continue
        if [ "$(basename "$d" | tr 'A-Z' 'a-z')" = "$want" ]; then
            mem="${d}memory/MEMORY.md"
            mem_src="path-folded store"
            break
        fi
    done
fi

if [ -z "$mem" ]; then
    printf '  %-34s %9s  %8d  no project store for this directory\n' \
        "MEMORY.md" "-" "$mem_limit"
else
    report "MEMORY.md" "$mem" "$mem_limit"

    # Name the file that was measured. "not present" is otherwise indistinguishable
    # from "measured the wrong path", which is the bug this section exists to prevent.
    printf '    resolved: %s (via %s)\n' "$mem" "$mem_src"

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
        # sits at or above whichever limit the row used, so every byte-cap truncation is
        # also a row breach, and counting both makes one file read as "2 over budget".
        if [ "$mb" -le "$mem_limit" ]; then
            if [ "$mb" -gt "$TRUNC_BYTES" ] || [ "$ml" -gt "$TRUNC_LINES" ]; then
                over=$((over + 1))
            fi
        fi
    fi
fi

# Emit the counts unconditionally: a run that measured nothing must not read as a pass.
if [ "$checked" -eq 0 ]; then
    if [ "$memory_only" -eq 1 ]; then
        # Say which file was not found. In this mode the CLAUDE.md files are skipped by
        # design, so "no always-loaded file found" would misdescribe what happened.
        echo "measured 0 files - no MEMORY.md resolved from $(pwd)"
    else
        echo "measured 0 files - no always-loaded file found from $(pwd)"
    fi
    exit 2
fi

if [ "$memory_only" -eq 1 ]; then
    if [ "$over" -eq 0 ]; then
        echo "MEMORY.md is under the cap: all $total B of it loads"
        exit 0
    fi
    echo "MEMORY.md is past the cap: its tail is not loading"
    exit 1
fi

printf 'measured %d files, %d B always loaded here: ' "$checked" "$total"
if [ "$over" -eq 0 ]; then
    echo "all under budget"
    exit 0
fi
echo "$over over budget"
exit 1
