#!/usr/bin/env bash
# Builds a throwaway project directory for one eval case.
#
# The eval runner spawns the executor with cwd set to the nearest ancestor
# containing a .claude/ directory, so a fixture has to BE a project, not a set of
# input files. Run the eval from inside the emitted directory.
#
#   ./build.sh --case reconcile-1 --out /tmp/fix && cd /tmp/fix
#
# Source trees keep their memory dir at `claude/` rather than `.claude/` because
# this repo's .gitignore excludes `.claude/`; the rename happens at build time.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASE=""
OUT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --case) CASE="$2"; shift 2 ;;
        --out)  OUT="$2";  shift 2 ;;
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

# Commits get fixed dates so a fixture is byte-identical between builds and the
# skill's "verified <date>" style records line up with real history.
commit() {
    git add -A
    GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -q -m "$2"
}

case "$CASE" in

reconcile-1)
    commit "2026-06-02T10:00:00" "Initial pipeline and notes"
    git checkout -q -b pipeline-refactor
    mkdir -p src
    echo "def load(path): ..." > src/ingest.py
    commit "2026-06-18T14:20:00" "Split ingest from transform"
    echo "def transform(df): ..." > src/transform.py
    commit "2026-06-19T09:05:00" "Move transform into its own module"
    echo "def emit(df): ..." > src/emit.py
    commit "2026-06-20T16:40:00" "Extract emit stage"
    git checkout -q main
    git merge -q --ff-only pipeline-refactor
    ;;

reconcile-2)
    # 40 real case files, so the suite's current size and split are countable rather
    # than something the agent has to take from the prompt or invent.
    for i in $(seq -w 1 22); do echo "type: lookup"   > "cases/lookup-$i-case.yaml"; done
    for i in $(seq -w 1 12); do echo "type: multihop" > "cases/multihop-$i-case.yaml"; done
    for i in $(seq -w 1 6);  do echo "type: negative" > "cases/negative-$i-case.yaml"; done
    commit "2026-03-14T11:00:00" "Benchmark harness and notes"
    ;;

reconcile-4)
    commit "2026-05-08T13:30:00" "Docker setup, documented in two places"
    ;;

reconcile-5)
    commit "2026-04-11T09:00:00" "Search index and status notes"
    mkdir -p ops
    echo "REBUILD_TARGET=staging" > ops/reindex.env
    commit "2026-07-21T15:10:00" "Rebuild search index on staging"
    echo "shards: 12" >> ops/reindex.env
    commit "2026-07-22T11:25:00" "Reshard staging index after rebuild"
    ;;

*)
    echo "case '$CASE' has no history recipe" >&2
    exit 2
    ;;
esac

echo "built $CASE at $OUT"
