#!/usr/bin/env bash
# Builds a throwaway project directory for one eval case.
#
# The eval runner spawns the executor with cwd set to the nearest ancestor
# containing a .claude/ directory, so a fixture has to BE a project, not a set of
# input files. Run the eval from inside the emitted directory.
#
#   ./build.sh --case distill-5 --out /tmp/fix && cd /tmp/fix
#
# Source trees keep their memory dir at `claude/` rather than `.claude/` because
# this repo's .gitignore excludes `.claude/`; the rename happens at build time.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASE=""
OUT=""
INSTALL_TRANSCRIPT=0

while [ $# -gt 0 ]; do
    case "$1" in
        --case) CASE="$2"; shift 2 ;;
        --out)  OUT="$2";  shift 2 ;;
        --install-transcript) INSTALL_TRANSCRIPT=1; shift ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

[ -n "$CASE" ] && [ -n "$OUT" ] || { echo "usage: $0 --case NAME --out DIR" >&2; exit 2; }
[ -d "$SRC/$CASE" ] || { echo "no such case: $CASE" >&2; ls "$SRC" >&2; exit 2; }

rm -rf "$OUT"
mkdir -p "$OUT"
cp -r "$SRC/$CASE/tree/." "$OUT/"
[ -d "$OUT/claude" ] && mv "$OUT/claude" "$OUT/.claude"

cd "$OUT"
git init -q -b main
git config user.name "Fixture"
git config user.email "fixture@example.invalid"

commit() {
    git add -A
    GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -q -m "$2"
}

case "$CASE" in

distill-1)
    # The history is the artifact half of the case: the timezone fix is visibly
    # pinned in the workflow (so it routes to "nowhere"), while the --runInBand
    # requirement appears only as a commit message and in no document.
    commit "2026-07-06T09:15:00" "Test suite and CI workflow"
    sed -i 's|    steps:|    env:\n      TZ: UTC\n    steps:|' .github/workflows/ci.yml
    commit "2026-07-14T11:02:00" "Pin TZ=UTC on the runner; local runs are Europe/London"
    sed -i 's|"test": "jest"|"test": "jest --runInBand"|' package.json
    commit "2026-07-14T15:48:00" "Serialise jest; parallel workers deadlock on the shared fixture db"
    sed -i 's|\[18\]|[18, 22]|' .github/workflows/ci.yml
    commit "2026-07-15T10:30:00" "Add node 22 to the matrix"
    ;;

distill-3)
    commit "2026-07-02T08:40:00" "e2e suite and project notes"
    ;;

distill-5)
    commit "2026-06-01T09:00:00" "Services before the migration"
    # Dates are explicit and ascending: the plan's ordering rationale (billing first
    # because it's recoverable, search last because lag is user-visible) is only
    # checkable against history if history preserves the order.
    set -- "billing:2026-07-08" "notifications:2026-07-15" "search:2026-07-22"
    for pair in "$@"; do
        svc="${pair%%:*}"; day="${pair##*:}"
        sed -i "s|queue: legacy|queue: rabbit|" "services/$svc/config.yaml"
        commit "${day}T13:00:00" "Move $svc onto the shared broker"
    done
    rm -f services/legacy-queue.md
    commit "2026-07-24T16:20:00" "Retire the legacy queue"
    ;;

distill-6)
    commit "2026-05-19T10:00:00" "Deploy script and notes"
    ;;

*)
    echo "case '$CASE' has no history recipe" >&2
    exit 2
    ;;
esac

echo "built $CASE at $OUT"

# A transcript can't live in the fixture: the skill looks for it under
# ~/.claude/projects/<slug>/, where slug is the project path with the separators
# flattened. Emit it into the fixture and print the install command rather than
# writing into the real ~/.claude by default — that directory holds the user's
# actual session history for any path that collides.
if [ -f "$SRC/$CASE/transcript.jsonl" ]; then
    session="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "00000000-0000-4000-8000-0000000000ff")"
    abs="$OUT"
    command -v cygpath >/dev/null 2>&1 && abs="$(cygpath -w "$OUT")"
    # Only the drive letter is lowercased; the rest of the path keeps its case.
    # C:\Users\Chris\x -> c--Users-Chris-x
    # Parameter expansion rather than sed/tr: on MSYS/Git Bash the argument
    # converter rewrites anything containing a slash or backslash before the
    # external command sees it, which silently mangles the substitution.
    # A literal backslash has to come from a variable: inside double quotes the
    # escape collapses before the pattern is matched, so "${s//\\/-}" silently
    # replaces nothing.
    bs='\'
    drive="${abs:0:1}"
    slug="${drive,,}${abs:1}"
    slug="${slug//:/-}"
    slug="${slug//"$bs"/-}"
    slug="${slug//\//-}"

    sed -e "s|__CWD__|$(printf '%s' "$abs" | sed 's|\\|\\\\\\\\|g')|g" \
        -e "s|__SESSION__|$session|g" \
        "$SRC/$CASE/transcript.jsonl" > "$OUT/fixture-transcript.jsonl"

    dest="$HOME/.claude/projects/$slug"
    if [ "$INSTALL_TRANSCRIPT" -eq 1 ]; then
        mkdir -p "$dest"
        cp "$OUT/fixture-transcript.jsonl" "$dest/$session.jsonl"
        echo "installed transcript at $dest/$session.jsonl"
        echo "remove it when you're done — it is indistinguishable from a real session"
    else
        echo
        echo "this case also needs a session transcript. to install it:"
        echo "  mkdir -p \"$dest\""
        echo "  cp \"$OUT/fixture-transcript.jsonl\" \"$dest/$session.jsonl\""
        echo "or re-run with --install-transcript."
    fi
fi
