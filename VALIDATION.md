# Validation Report — verifier robustness

**Date:** 2026-10-12
**Branch:** `advisor/005-verifier-robustness`
**Base commit:** `03369ee`
**Scope:** remediate two audit findings in `scripts/verify-skill.sh` and land the
previously-untracked verification baseline. No skill behavior changed.

---

## 1. Findings remediated

### MED-1 — Check 3 of the verifier passed vacuously

- **Location:** `scripts/verify-skill.sh:41-46` (pre-fix)
- **Root cause:** link extraction ran inside a process substitution feeding a
  `while read` loop (`done < <(grep ... | sed ... | sort -u)`). Under
  `set -euo pipefail`, a no-match `grep` makes the *pipeline* fail, but a
  process substitution's exit status never aborts the script. The loop simply
  received zero lines, its body never executed, and the script printed
  `ok: SKILL relative reference links resolve` having validated nothing.
- **Impact:** if every `](references/*.md)` link were stripped from `SKILL.md`,
  the verifier would exit 0 and report success while checking zero links. The
  check is the only guard on reference wiring, so the failure is silent — the
  exact failure mode a verifier exists to prevent. Partially masked in practice:
  check 1 independently catches a *missing* reference file, so the false pass
  only manifests as false assurance about links disappearing from `SKILL.md`.
- **Fix:** collect links into a variable first, assert non-empty, then iterate
  over the captured value. The check now also reports the link count.
- **Regression test:** `check3_links_stripped` in `scripts/test-verify-skill.sh`.

### MED-2 — The verification baseline was never committed

- **Location:** `git status` before this branch (`?? scripts/`, `?? plans/`,
  modified `README.md` + 3 skill files, branch `main`, HEAD `03369ee`)
- **Root cause:** plan 004 Step 3 (commit) was never executed. `plans/README.md:38`
  had already flagged this as outstanding.
- **Impact:** the only safety net in the repo — including the mechanism that
  would have caught MED-1 — was absent from version control and therefore
  unreachable to any collaborator or CI. There is also no `.gitignore`, so
  `.DS_Store` files surfaced as untracked noise in every `git status`.
- **Fix:** committed on a feature branch; added `.gitignore` for `.DS_Store`;
  marked plan 004's done criteria including "Commit on branch".

---

## 2. Tests added

`scripts/test-verify-skill.sh` — self-tests for the verifier. Zero dependencies,
matching the repo's stated convention (`plans/004:46`, "prefer POSIX shell; no npm").

Each case clones the repo into a temp dir, injects **one** fault, and asserts
both exit status and message. The real working tree is never modified; the temp
dir is removed by an `EXIT` trap. Covers every check on both its branches, where
a check has more than one failure mode:

| Case | Fault injected | Expected |
|---|---|---|
| `healthy_tree` | none | exit 0 |
| `check1_missing_reference` | delete `references/plan-template.md` | exit 1 |
| `check1_missing_manifest` | delete `.claude-plugin/plugin.json` | exit 1 |
| `check2_bad_name` | `name: improve` → `name: other` | exit 1 |
| `check3_link_target_missing` | append link to nonexistent reference | exit 1 |
| `check3_links_stripped` | strip **all** `](references/*.md)` links | exit 1 |
| `check4_readme_columns` | drop `Risk \| Evidence` from README table | exit 1 |
| `check4_skill_columns` | drop `Risk \| Evidence` from SKILL table | exit 1 |
| `check5_skills_add` | replace `npx skills add` line | exit 1 |
| `check5_marketplace` | remove marketplace mentions | exit 1 |
| `check6_advisor_plans_readme` | `advisor-plans` → `advisorPLANS` | exit 1 |
| `check6_advisor_plans_template` | same, in `plan-template.md` | exit 1 |
| `check7_hard_rule_phrase` | `Never modify source code` → `Never touch…` | exit 1 |
| `check7_hard_rules_section` | `## Hard Rules` → `## Guidelines` | exit 1 |

### Mutation test — proof the tests are not tautological

The new suite was run against the **pre-fix** `verify-skill.sh` to confirm it
actually detects the regression rather than merely passing:

```
FAIL  check3_links_stripped      expected exit 1, got 0 — FALSE PASS
test-verify-skill: passed=13 failed=1 skipped=0 blocked=0
exit 1
```

Exactly one case fails, and it is the MED-1 regression case. Every other case
passes on both versions, which is the correct result: MED-1 was the only defect.

#### Reproducing the mutation test

The pre-fix verifier was never itself committed (`scripts/` was untracked, which
is what MED-2 was about), so there is no `git show` that recovers it. Recreate it
by reverting check 3 to its original shape in a scratch copy:

```bash
d=$(mktemp -d) && tar --exclude='.git' -cf - . | tar -xf - -C "$d"
python3 - "$d" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]) / "scripts/verify-skill.sh"
s = p.read_text()
new = s[s.index("ref_links="):s.index('ok "SKILL relative reference links resolve')]
old = """while IFS= read -r rel; do
  target="skills/improve/${rel}"
  [[ -f "$target" ]] || fail "SKILL links to missing file: $rel (expected $target)"
done < <(grep -oE '\\]\\(references/[^)]+\\.md\\)' skills/improve/SKILL.md | sed 's/](\\(.*\\))/\\1/' | sort -u)
"""
p.write_text(s.replace(new, old))
PY
"$d/scripts/test-verify-skill.sh"; echo "exit=$?"   # expect: 13 passed / 1 failed
```

Expected terminal line:
`test-verify-skill: passed=13 failed=1 skipped=0 blocked=0`, exit 1.

---

## 3. Test results

Command: `./scripts/verify-skill.sh` and `./scripts/test-verify-skill.sh`

| Suite | Passed | Failed | Skipped | Blocked | Exit |
|---|---|---|---|---|---|
| `verify-skill.sh` (structural) | 7/7 checks | 0 | 0 | 0 | 0 |
| `test-verify-skill.sh` (self-tests) | 14/14 | 0 | 0 | 0 | 0 |
| `shellcheck scripts/*.sh` | clean | 0 | 0 | 0 | 0 |
| Mutation test (pre-fix verifier) | 13 | **1** | 0 | 0 | 1 *(expected)* |

**Regressions:** none. All 7 structural checks pass, and all 13 previously-passing
self-test cases still pass against the patched verifier — the patch changed check
3's link-collection mechanism and added a count to its message, nothing else.

**Acceptance criteria:** all of plan 004's done criteria (`plans/004:160-167`)
are now met, including "Commit on branch", which was outstanding.

---

## 4. Residual risks

| Risk | Severity | Note |
|---|---|---|
| Checks validate document *structure* only, not skill *behavior* | LOW | Structural drift is detectable; whether the written workflow still produces good plans is not automatable here. This is the same ceiling plan 004:178 flagged ("do not grow this into an LLM eval harness without a separate plan"). |
| Checks 2 and 5 use fixed-substring `grep`, so a rewording that preserves meaning still fails | LOW | Intentional — the checks encode plan 004's required literals. A reworded README will fail loudly, which is a false positive, not a silent miss. |
| `description:` frontmatter is unvalidated | MED | Not in scope here. It is the field that drives skill selection in the host, so drift would silently break discovery. Tracked as the next S-effort fix. |
| No CI | LOW | `.github/workflows/verify.yml` was explicitly declined at `plans/004:61`. Both scripts are exit-code-correct and CI-ready; adding a runner remains a maintainer decision. |
| `execute` / `reconcile` / `--issues` remain unexercised | LOW | They need a git worktree, a dispatched subagent, and GitHub write access. Read and reviewed, never run. Already triaged as host-portability work at `plans/README.md:29`. |

---

## 5. Reproducing

```bash
git checkout advisor/005-verifier-robustness
./scripts/verify-skill.sh      # structural checks  -> exit 0
./scripts/test-verify-skill.sh # verifier self-tests -> 14 passed, exit 0
```