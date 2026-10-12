#!/usr/bin/env bash
# Self-tests for verify-skill.sh.
#
# A verifier that cannot fail is worse than no verifier: it reports "ok" while
# checking nothing. These tests prove each check still detects its fault class by
# copying the repo to a temp dir, injecting one fault, and asserting the exit
# status and message. The real working tree is never modified.
#
# Run: ./scripts/test-verify-skill.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/verify-skill-tests.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
skip=0
blocked=0

for tool in tar mktemp perl grep; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "test-verify-skill: BLOCKED — required tool not found: $tool" >&2
    exit 2
  }
done

echo "test-verify-skill: checking $REPO_ROOT"

clone() {
  local d="$TMP/$1"
  rm -rf "$d"
  mkdir -p "$d"
  (cd "$REPO_ROOT" && tar --exclude='.git' --exclude='.DS_Store' -cf - .) \
    | (cd "$d" && tar -xf -)
  printf '%s' "$d"
}

# expect_ok <name> — tree is unmodified, verifier must accept it
expect_ok() {
  local name="$1" d out rc
  d="$(clone "$name")"
  out="$(cd "$d" && ./scripts/verify-skill.sh 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    printf '  FAIL  %-26s expected exit 0, got %d\n%s\n' "$name" "$rc" "$out"
    fail=$((fail + 1))
  else
    printf '  ok    %-26s exit 0\n' "$name"
    pass=$((pass + 1))
  fi
}

# expect_fail <name> <fault-command> <expected-message-substring>
expect_fail() {
  local name="$1" fault="$2" want="$3" d out rc
  d="$(clone "$name")"
  (cd "$d" && eval "$fault") >/dev/null 2>&1
  out="$(cd "$d" && ./scripts/verify-skill.sh 2>&1)"
  rc=$?
  if [[ $rc -eq 0 ]]; then
    printf '  FAIL  %-26s expected exit 1, got 0 — FALSE PASS\n' "$name"
    fail=$((fail + 1))
  elif [[ "$out" != *"$want"* ]]; then
    printf '  FAIL  %-26s exit %d, message lacked: %s\n        got: %s\n' \
      "$name" "$rc" "$want" "$(printf '%s' "$out" | tail -n 1)"
    fail=$((fail + 1))
  else
    printf '  ok    %-26s exit 1, detected\n' "$name"
    pass=$((pass + 1))
  fi
}

expect_ok "healthy_tree"

# check 1 — required files
expect_fail "check1_missing_reference" \
  'rm skills/improve/references/plan-template.md' \
  "missing required file"
expect_fail "check1_missing_manifest" \
  'rm .claude-plugin/plugin.json' \
  "missing required file"

# check 2 — frontmatter
expect_fail "check2_bad_name" \
  "perl -pi -e 's/^name: improve/name: other/' skills/improve/SKILL.md" \
  "frontmatter missing name: improve"

# check 3 — reference links resolve. Two distinct branches:
expect_fail "check3_link_target_missing" \
  "printf '\n[extra](references/nope.md)\n' >> skills/improve/SKILL.md" \
  "SKILL links to missing file"
expect_fail "check3_links_stripped" \
  "perl -pi -e 's/\\]\\(references\\/[^)]+\\.md\\)/[gone]/g' skills/improve/SKILL.md" \
  "reference wiring is missing"

# check 4 — findings table columns
expect_fail "check4_readme_columns" \
  "perl -pi -e 's/\\| Risk \\| Evidence \\|/| Risk |/' README.md" \
  "README.md example table header missing"
expect_fail "check4_skill_columns" \
  "perl -pi -e 's/\\| Risk \\| Evidence \\|/| Risk |/' skills/improve/SKILL.md" \
  "SKILL.md Phase 3 table header missing"

# check 5 — install paths
expect_fail "check5_skills_add" \
  "perl -pi -e 's|npx skills add shadcn/improve|npx skills add x/y|' README.md" \
  "README.md missing npx skills add"
expect_fail "check5_marketplace" \
  "perl -pi -e 's/marketplace/zzz/g; s/\\.claude-plugin/zzz/g' README.md" \
  "does not document marketplace"

# check 6 — advisor-plans wiring
expect_fail "check6_advisor_plans_readme" \
  "perl -pi -e 's/advisor-plans/advisorPLANS/g' README.md" \
  "README.md missing advisor-plans"
expect_fail "check6_advisor_plans_template" \
  "perl -pi -e 's/advisor-plans/advisorPLANS/g' skills/improve/references/plan-template.md" \
  "plan-template.md missing advisor-plans"

# check 7 — Hard Rules still forbid source edits
expect_fail "check7_hard_rule_phrase" \
  "perl -pi -e 's/Never modify source code/Never touch source code/' skills/improve/SKILL.md" \
  "missing Hard Rule phrase"
expect_fail "check7_hard_rules_section" \
  "perl -pi -e 's/^## Hard Rules/## Guidelines/' skills/improve/SKILL.md" \
  "missing ## Hard Rules section"

echo "  --    skipped: 0"
echo "  --    blocked: $blocked"
echo "test-verify-skill: passed=$pass failed=$fail skipped=$skip blocked=$blocked"

if [[ $fail -ne 0 ]]; then
  echo "test-verify-skill: FAIL" >&2
  exit 1
fi
echo "test-verify-skill: OK"
exit 0