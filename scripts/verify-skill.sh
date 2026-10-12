#!/usr/bin/env bash
# Structural checks for the improve skill package.
# Run from anywhere: ./scripts/verify-skill.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "verify-skill: FAIL — $*" >&2
  exit 1
}

ok() {
  echo "  ok: $*"
}

echo "verify-skill: checking $ROOT"

# 1. Required files
REQUIRED=(
  skills/improve/SKILL.md
  skills/improve/references/audit-playbook.md
  skills/improve/references/plan-template.md
  skills/improve/references/closing-the-loop.md
  README.md
  .claude-plugin/marketplace.json
  .claude-plugin/plugin.json
)
for f in "${REQUIRED[@]}"; do
  [[ -f "$f" ]] || fail "missing required file: $f"
done
ok "required files exist"

# 2. SKILL frontmatter
if ! head -n 20 skills/improve/SKILL.md | grep -q '^name: improve'; then
  fail "skills/improve/SKILL.md frontmatter missing name: improve"
fi
ok "SKILL frontmatter name: improve"

# 3. Relative reference links from SKILL resolve
# Collect links before looping: a process substitution's exit status never aborts
# under `set -e`, so an inlined `< <(grep ...)` passes while validating zero links.
ref_links="$(grep -oE '\]\(references/[^)]+\.md\)' skills/improve/SKILL.md | sed 's/](\(.*\))/\1/' | sort -u || true)"
[[ -n "$ref_links" ]] || fail "SKILL.md has no ](references/*.md) links — reference wiring is missing"
link_count="$(printf '%s\n' "$ref_links" | wc -l | tr -d ' ')"
while IFS= read -r rel; do
  target="skills/improve/${rel}"
  [[ -f "$target" ]] || fail "SKILL links to missing file: $rel (expected $target)"
done <<< "$ref_links"
ok "SKILL relative reference links resolve ($link_count link(s))"

# 4. Findings table columns (README example + SKILL Phase 3)
if ! grep -qE '\|[[:space:]]*#[[:space:]]*\|[[:space:]]*Finding[[:space:]]*\|[[:space:]]*Category[[:space:]]*\|[[:space:]]*Impact[[:space:]]*\|[[:space:]]*Effort[[:space:]]*\|[[:space:]]*Risk[[:space:]]*\|[[:space:]]*Evidence' skills/improve/SKILL.md; then
  fail "SKILL.md Phase 3 table header missing Impact/Effort/Risk/Evidence columns"
fi
if ! grep -qE '\|[[:space:]]*#[[:space:]]*\|[[:space:]]*Finding[[:space:]]*\|[[:space:]]*Category[[:space:]]*\|[[:space:]]*Impact[[:space:]]*\|[[:space:]]*Effort[[:space:]]*\|[[:space:]]*Risk[[:space:]]*\|[[:space:]]*Evidence' README.md; then
  fail "README.md example table header missing Impact/Effort/Risk/Evidence columns"
fi
ok "findings table columns aligned (README + SKILL)"

# 5. Marketplace documented + skills add still present
if ! grep -qiE 'marketplace|\.claude-plugin' README.md; then
  fail "README.md does not document marketplace / .claude-plugin install path"
fi
if ! grep -q 'npx skills add shadcn/improve' README.md; then
  fail "README.md missing npx skills add shadcn/improve"
fi
ok "marketplace + skills-add install paths documented"

# 6. advisor-plans wiring
for f in \
  skills/improve/SKILL.md \
  skills/improve/references/plan-template.md \
  skills/improve/references/closing-the-loop.md \
  README.md
do
  grep -q 'advisor-plans' "$f" || fail "$f missing advisor-plans mention"
done
ok "advisor-plans wired in SKILL, template, closing-the-loop, README"

# 7. Hard Rules still forbid source edits
if ! grep -q 'Never modify source code' skills/improve/SKILL.md; then
  fail "SKILL.md missing Hard Rule phrase 'Never modify source code'"
fi
if ! grep -q '## Hard Rules' skills/improve/SKILL.md; then
  fail "SKILL.md missing ## Hard Rules section"
fi
ok "Hard Rules still forbid source edits"

echo "verify-skill: OK"
exit 0
