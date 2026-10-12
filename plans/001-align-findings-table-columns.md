# Plan 001: Align findings-table columns in README with SKILL

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 03369ee..HEAD -- README.md skills/improve/SKILL.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: docs
- **Planned at**: commit `03369ee`, 2026-08-05

## Why this matters

The skill's Phase 3 mandates a findings table with columns
`# | Finding | Category | Impact | Effort | Risk | Evidence`. The public
README example uses a different schema (`Effort`, `Confidence` only — no
Impact, Risk, or Evidence). Agents and humans who mirror the README produce
reports that fail the skill's own presentation contract. One short edit
makes the marketed example match the runtime instruction.

## Current state

- `skills/improve/SKILL.md` — Phase 3 table (canonical):

```markdown
| # | Finding | Category | Impact | Effort | Risk | Evidence |
```

(at the "Present the vetted findings table" section)

- `README.md` — Example section (diverged):

```
| # | Finding                                        | Category  | Effort | Confidence |
|---|------------------------------------------------|-----------|--------|------------|
| 1 | shadow-config duplicated in search.ts/view.ts, | tech-debt | M      | HIGH       |
|   | copies already drifted (TODO at search.ts:31)  |           |        |            |
| 2 | O(n²) icon migration (migrate-icons.ts:168)    | perf      | S      | HIGH       |
```

Conventions: plain markdown, concise prose, match the rest of README tone.
Do not invent fake Impact/Risk text that contradicts the known shadcn/ui
example intent — fill plausible columns from the finding text already shown.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Drift check | `git diff --stat 03369ee..HEAD -- README.md skills/improve/SKILL.md` | empty or only expected prior work |
| Column check | `rg -n 'Finding.*Category.*Impact.*Effort.*Risk.*Evidence' README.md` | ≥1 match in the example table |
| Old schema gone | `rg -n 'Category  \| Effort \| Confidence' README.md` | no matches |
| SKILL unchanged for this plan | `git diff -- skills/improve/SKILL.md` | empty (this plan does not edit SKILL) |

## Scope

**In scope**:
- `README.md` only

**Out of scope**:
- `skills/improve/SKILL.md` — table there is the source of truth; do not change it
- `skills/improve/references/*`
- `examples/*`
- `plans/*` (reviewer maintains index)

## Git workflow

- Branch: `advisor/001-align-findings-table-columns`
- Commit message style (from repo log): `docs: ...` e.g. `docs: fix link to Agent Skills`
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Rewrite the example findings table in README.md

Replace the example table under "Example" so its header is exactly:

```
| # | Finding | Category | Impact | Effort | Risk | Evidence |
```

Keep two sample rows about shadow-config and O(n²) icon migration. Suggested fill (edit for line length/readability as needed; keep meaning):

| # | Finding | Category | Impact | Effort | Risk | Evidence |
|---|----------|----------|--------|--------|------|----------|
| 1 | shadow-config duplicated in search.ts/view.ts; copies already drifted (TODO at search.ts:31) | tech-debt | Future partial-config changes must be made twice; copies already diverged | M | LOW | search.ts / view.ts shadow-config blocks |
| 2 | O(n²) icon migration (migrate-icons.ts:168) | perf | Slow icon migrations on large trees | S | LOW | migrate-icons.ts:168 |

Remove the `Confidence` column from this example (confidence remains in the finding format inside the skill/playbook; the Phase 3 *presentation* table uses Impact/Effort/Risk/Evidence).

**Verify**:
```bash
rg -n 'Finding.*Category.*Impact.*Effort.*Risk.*Evidence' README.md
rg -n 'Category  \| Effort \| Confidence' README.md || true
```
First command matches the new header. Second finds no old dual-space `Category  | Effort | Confidence` example header.

### Step 2: Commit

```bash
git add README.md
git commit -m "docs: align README findings table with SKILL Phase 3 columns"
```

**Verify**: `git show --stat HEAD` shows only `README.md`.

## Test plan

- No automated test suite in this repo. Verification is the `rg` commands above.
- Manual: open README Example section and confirm columns match SKILL.md Phase 3.

## Done criteria

- [ ] README example table header includes Impact, Effort, Risk, Evidence (in that order after Category)
- [ ] README example table no longer uses Confidence as a column
- [ ] `skills/improve/SKILL.md` unmodified by this plan
- [ ] No files outside in-scope list modified
- [ ] Commit exists on branch `advisor/001-align-findings-table-columns` (or worktree equivalent)

## STOP conditions

- SKILL.md Phase 3 table no longer uses `| # | Finding | Category | Impact | Effort | Risk | Evidence |` — stop; the plan's source of truth drifted.
- Another plan already rewrote the Example section incompatibly — stop and report.

## Maintenance notes

- Any future README marketing of findings output must copy the SKILL Phase 3 header, not invent columns.
- Confidence still belongs in per-finding playbook format; do not re-add it to the summary table without updating SKILL Phase 3 first.
