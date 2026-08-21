#!/bin/sh
# Assert that every plugin's manifest version matches its skill's frontmatter version.
#
# The two numbers are maintained by hand in separate files and have drifted apart four
# times, in both directions — the manifest ahead of the skill as often as behind it.
# Run this before committing anything that touches a version.
#
#   sh scripts/check-versions.sh   ; echo $?    # 0 = all match, 1 = at least one does not
#
# Chain it with `;` rather than `&&`: a non-zero exit is the informative answer here.

cd "$(dirname "$0")/.." || exit 2

plugins=0
compared=0
bad=0

for manifest in plugins/*/.claude-plugin/plugin.json; do
    [ -e "$manifest" ] || continue
    plugins=$((plugins + 1))
    dir=$(dirname "$(dirname "$manifest")")
    name=$(basename "$dir")

    mv=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1)
    if [ -z "$mv" ]; then
        printf '  %-22s FAIL  no "version" in %s\n' "$name" "$manifest"
        bad=$((bad + 1))
        continue
    fi

    # A plugin need not ship a skill — grounded-output-style ships an output style.
    # Report that rather than skipping silently, so a vanished SKILL.md is visible.
    skills=$(find "$dir" -name SKILL.md 2>/dev/null)
    if [ -z "$skills" ]; then
        printf '  %-22s %-8s  no SKILL.md, nothing to compare\n' "$name" "$mv"
        continue
    fi

    for skill in $skills; do
        compared=$((compared + 1))
        sv=$(sed -n '/^version:[[:space:]]*/s///p' "$skill" | head -1 | tr -d '[:space:]')
        if [ -z "$sv" ]; then
            printf '  %-22s FAIL  %s has no version: field\n' "$name" "$skill"
            bad=$((bad + 1))
        elif [ "$mv" = "$sv" ]; then
            printf '  %-22s %-8s == %s\n' "$name" "$mv" "$sv"
        else
            printf '  %-22s %-8s != %-8s manifest vs %s\n' "$name" "$mv" "$sv" "$skill"
            bad=$((bad + 1))
        fi
    done
done

# Emit the counts unconditionally: a run that compared nothing must not read as a pass.
if [ "$plugins" -eq 0 ]; then
    echo "checked 0 plugins — no plugins/*/.claude-plugin/plugin.json found; run this from the repo"
    exit 2
fi

printf 'checked %d plugins, %d versioned skills: ' "$plugins" "$compared"
if [ "$bad" -eq 0 ]; then
    echo "all match"
    exit 0
fi
echo "$bad mismatch(es)"
exit 1
