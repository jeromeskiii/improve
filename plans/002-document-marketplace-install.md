# Plan 002: Document Claude marketplace install path

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 03369ee..HEAD -- README.md .claude-plugin/marketplace.json .claude-plugin/plugin.json`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (serialise after 001 if both edit README)
- **Category**: docs
- **Planned at**: commit `03369ee`, 2026-08-05

## Why this matters

PR #12 added Claude Code marketplace metadata under `.claude-plugin/`, but the
README Install section only documents `npx skills add shadcn/improve`. Users
looking for the marketplace path never learn it exists. Documenting both
install paths is a small README change with no behavioral risk.

## Current state

- `README.md` Install section today:

```markdown
## Install

```bash
npx skills add shadcn/improve
```

Works in any agent that supports [Agent Skills](https://agentskills.io) format. The plans it writes are plain markdown, so any agent (or human) can pick them up.
```

- `.claude-plugin/marketplace.json` — marketplace catalog:

```json
{
  "name": "improve",
  "owner": { "name": "shadcn" },
  "metadata": {
    "description": "Claude marketplace catalog for the improve plugin."
  },
  "plugins": [
    { "name": "improve", "source": "./" }
  ]
}
```

- `.claude-plugin/plugin.json` — plugin metadata: name `improve`, homepage `https://github.com/shadcn/improve`, version `1.0.0`.
- Skill lives at `skills/improve/SKILL.md` (default Claude plugin skills path).

Conventions: short Install section; keep Agent Skills sentence; do not invent CLI flags that are not in Claude docs if unsure — prefer linking to Claude plugin/marketplace docs and stating the repo is a marketplace root via `.claude-plugin/marketplace.json`.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Drift | `git diff --stat 03369ee..HEAD -- README.md .claude-plugin/` | expected prior only |
| Marketplace mentioned | `rg -n -i 'marketplace|claude-plugin|\.claude-plugin' README.md` | ≥1 match |
| skills add still present | `rg -n 'npx skills add shadcn/improve' README.md` | 1 match |

## Scope

**In scope**:
- `README.md` (Install section only — do not rewrite Usage/How it works)

**Out of scope**:
- `.claude-plugin/*` contents (already correct; do not "fix" JSON)
- SKILL.md / references
- inventing a custom slash-command surface

## Git workflow

- Branch: `advisor/002-document-marketplace-install`
- Commit: `docs: document Claude marketplace install path`
- Do NOT push or open a PR unless instructed.

## Steps

### Step 1: Expand Install section

Replace/expand the Install section so it documents **two** paths:

1. **Agent Skills (any compatible agent)** — keep:
   ```bash
   npx skills add shadcn/improve
   ```

2. **Claude Code marketplace / plugin** — add a short subsection stating:
   - This repo is a Claude plugin marketplace root (`.claude-plugin/marketplace.json`).
   - Plugin source is `./` and skills load from `skills/improve/`.
   - How to add a marketplace from a GitHub repo in Claude Code (use the standard pattern if known):
     ```text
     /plugin marketplace add shadcn/improve
     ```
     or document: add the GitHub repo `shadcn/improve` as a marketplace, then install the `improve` plugin from it.
   - Link to Claude Code plugins/marketplace docs if a stable URL is known (`https://code.claude.com/docs/en/plugin-marketplaces` or plugins reference). If uncertain of the exact slash command wording in the latest Claude Code, prefer: "Add this repository as a Claude Code plugin marketplace (see Claude Code plugin marketplace docs), then install the `improve` plugin." rather than inventing a wrong command.

Keep the closing sentence about Agent Skills format and plain-markdown plans.

**Verify**:
```bash
rg -n -i 'marketplace' README.md
rg -n 'npx skills add shadcn/improve' README.md
rg -n '\.claude-plugin' README.md
```
All three should hit Install (or immediately adjacent) content.

### Step 2: Commit

```bash
git add README.md
git commit -m "docs: document Claude marketplace install path"
```

**Verify**: `git show --stat HEAD` → only README.md

## Test plan

- Grep checks above.
- No unit tests.

## Done criteria

- [ ] README Install documents both `npx skills add` and Claude marketplace/plugin path
- [ ] README mentions `.claude-plugin` or marketplace catalog for this repo
- [ ] Existing skills-add command still present and correct
- [ ] No edits outside `README.md`
- [ ] Commit on branch

## STOP conditions

- `.claude-plugin/marketplace.json` or plugin layout removed/renamed — stop; docs would be wrong.
- Install section already documents marketplace fully — mark done / no-op and report.

## Maintenance notes

- When marketplace install CLI changes, update this Install subsection only.
- Fork maintainers (non-shadcn remotes) may need a one-line note later; out of scope here — keep upstream `shadcn/improve` naming.
