#!/usr/bin/env bash
# Stop-hook gate: if this turn left Swift changes in the tree, swiftlint must be clean
# before the turn can end. Errors block (exit 2); warnings are reported, not blocking,
# because a pre-existing warning would otherwise wedge every turn.
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

payload=$(cat 2>/dev/null || true)

# Already re-entered after this hook blocked once: let the turn end instead of looping.
case "$payload" in
    *'"stop_hook_active": true'* | *'"stop_hook_active":true'*) exit 0 ;;
esac

command -v swiftlint >/dev/null 2>&1 || exit 0

# Only gate turns that actually touched Swift — staged, unstaged or untracked.
[ -n "$(git status --porcelain -- '*.swift' 2>/dev/null)" ] || exit 0

output=$(swiftlint lint --quiet 2>&1)
errors=$(printf '%s\n' "$output" | grep -c ': error:')
warnings=$(printf '%s\n' "$output" | grep -c ': warning:')

if [ "$errors" -gt 0 ]; then
    {
        echo "swiftlint: $errors error(s). CLAUDE.md requires a clean lint before reporting done — fix these, then finish."
        printf '%s\n' "$output" | grep ': error:' | head -40
    } >&2
    exit 2
fi

if [ "$warnings" -gt 0 ]; then
    printf '{"systemMessage": "swiftlint: 0 errors, %s warning(s)."}\n' "$warnings"
fi

exit 0
