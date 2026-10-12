# Plan 003: Wire advisor-plans/ through template, execute, reconcile, and README

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 03369ee..HEAD -- skills/improve/SKILL.md skills/improve/references/plan-template.md skills/improve/references/closing-the-loop.md README.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none (merge carefully if 001/002 already edited README)
- **Category**: bug
- **Planned at**: commit `03369ee`, 2026-08-05

## Why this matters

Hard Rule 1 allows writing under `advisor-plans/` when `plans/` already exists
for an unrelated purpose. Phase 4 mentions the same exception. But the plan
template, `closing-the-loop.md` (execute + reconcile), and README hard rules
still hardcode `plans/` only. A literal executor or reconcile pass will look
for `plans/README.md`, update the wrong directory, or violate Hard Rule 1.
Finish the output-dir story so every follow-through path uses a single rule:
**default `plans/`; if that path is taken for non-improve work, use
`advisor-plans/` and treat that as the plans root for the rest of the session.**

## Current state

### SKILL.md Hard Rule 1 (partially fixed)

```
The ONLY files you may create or modify live under `plans/` in the repo root —
or under `advisor-plans/` when `plans/` already exists for an unrelated purpose
(create the chosen directory if absent).
```

Phase 4 also says: if `plans/` exists for some unrelated purpose, use
`advisor-plans/` instead and say so. Index path still written as
`plans/README.md` without "or advisor-plans/README.md".

### plan-template.md (hardcoded)

- File naming: `plans/NNN-short-slug.md`
- Index: `plans/README.md`
- Done criteria: update `plans/README.md`

### closing-the-loop.md (hardcoded)

- Preconditions: dependencies DONE in `plans/README.md`
- Uncommitted plans note: `plans/`
- Reviewer override: skip updating `plans/README.md`
- Section title: `reconcile` — keep `plans/` alive
- Process: Read `plans/README.md`

### README.md Hard rules

```
- Never modifies source code itself. The only writes go to `plans/`; executors
  edit only in disposable worktrees, and merging is always yours.
```

No `advisor-plans/` mention.

### Vocabulary to use everywhere

Introduce a short term once in SKILL Phase 4 (or Hard Rule 1) and reuse:

- **Plans root**: `plans/` by default. Use `advisor-plans/` only when `plans/`
  already exists for an unrelated purpose. After the choice is made, every
  path that said `plans/` means `<plans-root>/` (including `README.md` index
  and `NNN-slug.md` files).

Do **not** invent a third directory name.

Conventions: same prose density as existing skill docs; prefer one clarifying
sentence over long new sections. Match commit style `fix:` / `docs:`.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Find remaining hardcodes that ignore the exception | `rg -n 'plans/' skills/improve/ README.md` | after fix, every operational mention either is the default name with adjacent advisor-plans exception, or clearly means "plans root" |
| advisor-plans in template | `rg -n 'advisor-plans' skills/improve/references/plan-template.md` | ≥1 |
| advisor-plans in closing-the-loop | `rg -n 'advisor-plans' skills/improve/references/closing-the-loop.md` | ≥1 |
| advisor-plans in README hard rules | `rg -n 'advisor-plans' README.md` | ≥1 |
| examples untouched | `git diff -- examples/` | empty |

## Scope

**In scope**:
- `skills/improve/SKILL.md`
- `skills/improve/references/plan-template.md`
- `skills/improve/references/closing-the-loop.md`
- `README.md` (Hard rules bullet about writes only; optionally one word in "Plans land in `plans/`" flow if needed for honesty)

**Out of scope**:
- `examples/001-extract-shadow-config-resolution.md` (frozen sample; leave as historical `plans/`)
- audit-playbook.md
- Host-specific execute tool names (sonnet/SendMessage/Explore) — deferred finding
- Creating actual `advisor-plans/` in this repo
- Renaming this repo's `plans/` directory produced by improve

## Git workflow

- Branch: `advisor/003-wire-advisor-plans-output-dir`
- Commit: `fix: wire advisor-plans/ through template and closing-the-loop`
- Do NOT push or open a PR unless instructed.

## Steps

### Step 1: SKILL.md — define plans root once; use it in Phase 4 / variants

1. After Hard Rule 1 (or inside Phase 4 before the `plans/` tree diagram), add a crisp **Plans root** definition:
   - Default directory: `plans/`
   - Exception: if `plans/` already exists for an unrelated purpose, use `advisor-plans/` and tell the user
   - Once chosen, call it the plans root; index is `<plans-root>/README.md`; plan files are `<plans-root>/NNN-slug.md`
2. Update the Phase 4 tree diagram to show both possibilities, e.g.:

```
plans/   (or advisor-plans/ when plans/ is taken for something else)
  README.md
  001-<slug>.md
```

3. Where Phase 4 / non-interactive default / review-plan / finish steps say only `plans/README.md`, add "under the plans root" wording so an agent using `advisor-plans/` is not redirected back to `plans/`.
4. Do not remove the Hard Rule 1 exception; keep it as the single source of truth and make other sections defer to it.

**Verify**: `rg -n 'plans root|advisor-plans' skills/improve/SKILL.md` shows both the definition and at least one Phase 4 reference.

### Step 2: plan-template.md — parameterize plans root

At the top (after the three properties, before Template), add:

> **Plans root**: write under `plans/` unless the advisor selected `advisor-plans/`
> (when `plans/` is taken). Below, `plans/` means that chosen root.

Then either:
- Keep showing `plans/` in the template as the default spelling **and** add one explicit note on the Index section: "If plans root is `advisor-plans/`, the index is `advisor-plans/README.md` and file naming is `advisor-plans/NNN-short-slug.md`", or
- Use `<plans-root>/` placeholders in the template skeleton.

Prefer the note + default `plans/` spelling so examples stay readable, matching how Hard Rule 1 is written.

Update Done criteria bullet that only names `plans/README.md` to "status row in `<plans-root>/README.md`".

**Verify**: `rg -n 'advisor-plans|plans root|plans-root' skills/improve/references/plan-template.md`

### Step 3: closing-the-loop.md — execute + reconcile use plans root

1. In execute preconditions: dependencies DONE in `<plans-root>/README.md` (default `plans/`).
2. Uncommitted plans note: if the plans root is uncommitted, inline the plan (same as today for `plans/`).
3. Reviewer override: skip updating index under plans root.
4. Reconcile section: title can stay friendly ("keep the plan backlog alive") but body must say read `<plans-root>/README.md` and every plan file under that root; mention `advisor-plans/` when that was the chosen root.
5. `--issues` can keep "plan file" language; no need for deep changes unless a path is hardcoded.

**Verify**: `rg -n 'advisor-plans|plans root|plans-root' skills/improve/references/closing-the-loop.md`

### Step 4: README Hard rules

Update the bullet:

```
- Never modifies source code itself. The only writes go to `plans/` (or
  `advisor-plans/` when `plans/` already exists for an unrelated purpose);
  executors edit only in disposable worktrees, and merging is always yours.
```

Optional: in "How to use" step 3, add a parenthetical that the directory is `advisor-plans/` when `plans/` is already taken — only if it stays one line.

**Verify**: `rg -n 'advisor-plans' README.md`

### Step 5: Consistency sweep

```bash
rg -n 'plans/README.md' skills/improve/ README.md
```

Every hit should either:
- be default-path documentation next to the advisor-plans exception, or
- clearly mean "index under the plans root".

No instruction should say "always use `plans/`" in a way that contradicts Hard Rule 1.

**Verify**: manual read of Hard Rule 1 + Phase 4 + template header + reconcile open paragraphs.

### Step 6: Commit

```bash
git add skills/improve/SKILL.md \
  skills/improve/references/plan-template.md \
  skills/improve/references/closing-the-loop.md \
  README.md
git commit -m "fix: wire advisor-plans/ through template and closing-the-loop"
```

**Verify**: `git show --stat HEAD` lists only in-scope files.

## Test plan

- Grep verification above.
- After plan 004 lands, the structural script should assert `advisor-plans` appears in SKILL, plan-template, closing-the-loop, and README.

## Done criteria

- [ ] SKILL defines plans root / advisor-plans exception and Phase 4 uses it
- [ ] plan-template mentions advisor-plans or plans root for file naming and index
- [ ] closing-the-loop execute + reconcile do not hard-require only `plans/` without the exception
- [ ] README hard rules mention advisor-plans
- [ ] `examples/` unmodified
- [ ] No out-of-scope files changed
- [ ] Commit on branch

## STOP conditions

- Hard Rule 1 no longer mentions advisor-plans (upstream reverted) — stop and re-read intent.
- A prior edit to README Hard rules from plan 001/002 conflicts — merge text, do not clobber Install or Example sections.
- You believe fixing this requires executable code (scripts) — that is plan 004; do not expand scope.

## Maintenance notes

- Future references to the output directory must use "plans root" language or restate the exception.
- Reviewers should reject PRs that re-hardcode `plans/` in execute/reconcile without the exception.
- Frozen examples may keep `plans/` forever.
