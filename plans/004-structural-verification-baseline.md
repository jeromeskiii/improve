# Plan 004: Add structural verification script for skill docs

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 03369ee..HEAD -- skills/improve/ README.md package.json scripts/`
> If plans 001–003 have already landed, that is expected — re-read live files
> and encode **post-001–003** truth in the checks, not the old broken schemas.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: plans/001, plans/002, plans/003 (prefer landed; if not, still write checks that match *intended* end state and note failures)
- **Category**: tests
- **Planned at**: commit `03369ee`, 2026-08-05

## Why this matters

This repo's product is instruction quality. There is no package manager, CI, or
test suite, so doc regressions (findings-table column drift, missing
advisor-plans wiring, broken relative links) only show up in human review.
A small zero-dependency shell script that fails on known inconsistency classes
gives executors and contributors a one-command verification gate.

## Current state

- No `package.json`, no `.github/workflows`, no `scripts/`.
- Skill entry: `skills/improve/SKILL.md`
- References (linked from SKILL with relative paths):
  - `skills/improve/references/audit-playbook.md`
  - `skills/improve/references/plan-template.md`
  - `skills/improve/references/closing-the-loop.md`
- After plans 001–003 (intended end state this script should enforce):
  - README example table header matches SKILL Phase 3:
    `| # | Finding | Category | Impact | Effort | Risk | Evidence |`
  - README Install mentions marketplace / Claude plugin path and still has
    `npx skills add shadcn/improve`
  - `advisor-plans` appears in SKILL.md, plan-template.md, closing-the-loop.md,
    and README.md
- Conventions: minimal tooling; prefer POSIX shell + `rg` or `grep`; no npm.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Run checks | `./scripts/verify-skill.sh` | exit 0, prints OK summary |
| From repo root | `bash scripts/verify-skill.sh` | same |
| Fail on purpose (optional) | temporarily break a check | exit non-zero |

## Scope

**In scope** (create/modify):
- `scripts/verify-skill.sh` (create, executable)
- `README.md` — one line under Install or a tiny "Development" / "Verify" note pointing at the script (optional but preferred if it stays ≤3 lines)
- `.github/workflows/verify.yml` (optional — only if adding CI is trivial; **prefer script-only** if unsure about repo CI policy)

**Out of scope**:
- Full agent evals / golden plan LLM judges
- npm/pnpm toolchain
- Changing skill behavior beyond what 001–003 already did
- Editing `examples/` content for the frozen sample

## Git workflow

- Branch: `advisor/004-structural-verification-baseline`
- Commit: `test: add structural verify-skill script`
- Do NOT push or open a PR unless instructed.

## Steps

### Step 1: Create `scripts/verify-skill.sh`

Create an executable bash script that `cd`s to repo root (script lives in `scripts/`) and runs checks. Use `set -euo pipefail`. On failure, print which check failed and exit 1. On success, print `verify-skill: OK` and exit 0.

**Required checks** (implement all):

1. **Required files exist**
   - `skills/improve/SKILL.md`
   - `skills/improve/references/audit-playbook.md`
   - `skills/improve/references/plan-template.md`
   - `skills/improve/references/closing-the-loop.md`
   - `README.md`
   - `.claude-plugin/marketplace.json`
   - `.claude-plugin/plugin.json`

2. **SKILL frontmatter**
   - `skills/improve/SKILL.md` starts with YAML frontmatter containing `name: improve`

3. **Relative reference targets**
   - Every `](references/....md)` link in `skills/improve/SKILL.md` resolves to an existing file under `skills/improve/`

4. **Findings table alignment**
   - `README.md` contains a table header with Finding, Category, Impact, Effort, Risk, Evidence (same logical columns as SKILL Phase 3)
   - `skills/improve/SKILL.md` still contains `| # | Finding | Category | Impact | Effort | Risk | Evidence |` (allow flexible spacing)

5. **Marketplace documented**
   - `README.md` matches marketplace (case-insensitive) OR `.claude-plugin`
   - `README.md` still contains `npx skills add shadcn/improve`

6. **advisor-plans wiring**
   - `rg -q 'advisor-plans' skills/improve/SKILL.md`
   - same for `plan-template.md`, `closing-the-loop.md`, `README.md`

7. **Hard Rule 1 still forbids source edits** (smoke)
   - SKILL.md still contains a Hard Rules section and the phrase about never modifying source code (or "Never modify source code")

Do **not** require network. Do **not** call `git` for pass/fail of content (git optional for printing HEAD).

**Verify**:
```bash
chmod +x scripts/verify-skill.sh
./scripts/verify-skill.sh
echo exit:$?
```
Expect exit 0 **only if** 001–003 content is already present. If 001–003 are not merged into the worktree, either:
- STOP and report that dependencies are missing, or
- implement 001–003 first is not this plan's job — leave script correct for end state and report FAIL with which checks fail if deps missing.

Prefer: if dependency checks fail, exit non-zero with a clear message listing failed checks (that is correct behavior). Reviewer/user merges 001–003 first.

### Step 2: Document how to run it

Add a brief note to README — either under Install or a new `## Development` section with only:

```markdown
## Development

```bash
./scripts/verify-skill.sh
```

Structural checks for skill docs (links, table columns, output-dir wiring).
```

Keep it short.

**Verify**: `rg -n 'verify-skill' README.md`

### Step 3: Commit

```bash
git add scripts/verify-skill.sh README.md
git commit -m "test: add structural verify-skill script"
```

**Verify**: `git show --stat HEAD`; `./scripts/verify-skill.sh` exits 0 when 001–003 are present.

## Test plan

- Primary: `./scripts/verify-skill.sh` exit 0 on healthy tree.
- Negative (manual once): comment out `advisor-plans` in a copy — script should fail; do not leave the tree broken.
- No JS/Python test framework.

## Done criteria

- [x] `scripts/verify-skill.sh` exists, is executable, uses `set -euo pipefail`
- [x] Script implements checks 1–7 above
- [x] `./scripts/verify-skill.sh` exits 0 on a tree that includes 001–003 outcomes
- [x] README mentions how to run the script
- [x] No out-of-scope files changed
- [x] Commit on branch

Verified 2026-10-12 on branch `advisor/005-verifier-robustness`. See
[../VALIDATION.md](../VALIDATION.md). Note: criterion 6 was outstanding until
this branch landed — `scripts/` had been untracked since the plan was written.

### Follow-up closed in the same branch

`scripts/test-verify-skill.sh` (create) — self-tests proving each check still
detects its fault class. An audit found check 3 passed vacuously when
`SKILL.md` contained no `](references/*.md)` links; it is now fixed and the
false-pass case is a regression test.

## STOP conditions

- Plans 001–003 not applied and you cannot get green without rewriting skill content yourself beyond the script/README note — stop, ship the script + README note, report which checks fail (STATUS can be COMPLETE with NOTES that verify is red until deps land).
- Repo gains a different official test runner mid-flight — integrate rather than duplicate if obvious; else stop and report.

## Maintenance notes

- When changing the findings table columns in SKILL, update check 4 in the same PR.
- When adding new `references/*.md` linked from SKILL, check 3 catches missing files automatically if links use `](references/...)`.
- Do not grow this into an LLM eval harness without a separate plan.
