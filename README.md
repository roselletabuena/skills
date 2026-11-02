# agent-skills

Agent skills for spec-driven development, git workflows, and engineering automation,
packaged as a Claude Code **plugin marketplace**. Each plugin is a self-contained bundle
of skills that can be installed on its own.

The skills are plain `SKILL.md` files (the [Agent Skills](https://agentskills.io) format),
so they are not tied to one tool: Claude Code gets a one-command install, and other agents
that read the same format can use the skill folders directly. See
[Other agents](#other-agents).

| Plugin | What it does |
| :--- | :--- |
| [**speckit-orchestrator**](plugins/speckit-orchestrator/) | An orchestration layer for [GitHub Spec Kit](https://github.com/github/spec-kit): drives one feature end to end in an isolated git worktree behind an 8-artifact gate, batch-executes tickets with failure isolation, and runs autonomous sprints via context-isolated subagents. Five skills. |
| [**git-workflows**](plugins/git-workflows/) | Git skills for the places the obvious approach quietly goes wrong. `git-atomic-commit` splits working-tree changes into single-purpose commits, ordered so each builds and messaged to match the repository's style (with an eval suite). `git-stacked-pr-rebase` restacks dependent PRs after a lower one is squash-merged or amended. `git-safe-history-rewrite` decides revert vs. rewrite and pushes with a lease. `git-undo-recovery` gets lost commits, branches and stashes back via the reflog. `git-conflict-resolution` resolves conflicts by combining intent, not picking a side. `git-bisect-regression` finds the commit that broke something. `git-branch-cleanup` deletes merged branches, squash-merged ones included, without losing work. Seven skills. |

---

## Installation

### Claude Code

Add the marketplace once, then install whichever plugins you want:

```bash
claude plugin marketplace add roselletabuena/skills
claude plugin install speckit-orchestrator@agent-skills
claude plugin install git-workflows@agent-skills
```

Or from inside a session: `/plugin marketplace add roselletabuena/skills`, then install
from the `/plugin` panel.

To try one without installing, point Claude Code straight at its directory:

```bash
claude --plugin-dir ./plugins/git-workflows
```

### Other agents

Any agent that reads `SKILL.md` can use these skills. The quickest route is the open
[`skills`](https://github.com/vercel-labs/skills) CLI behind [skills.sh](https://skills.sh),
which supports Claude Code, Codex, Cursor, OpenCode and many others:

```bash
# see what is available
npx skills add roselletabuena/skills --list

# install one skill into the current project
npx skills add roselletabuena/skills --skill git-stacked-pr-rebase

# add -g for all projects, -a to target a specific agent
npx skills add roselletabuena/skills --skill git-stacked-pr-rebase -g -a claude-code
```

The `speckit-orchestrator` skills depend on each other, so install them together; the exact
command is in [its README](plugins/speckit-orchestrator/README.md#skillssh-and-other-agents).

Or copy a skill folder by hand (for example `plugins/git-workflows/skills/git-atomic-commit/`)
into the directory your agent discovers skills from. For Google Antigravity that is
`<workspace>/.agent/skills/` for one project or `~/.gemini/antigravity/skills/` for all
projects; restart the agent session afterwards so it re-detects them. Check your agent's
docs for its own path.

Not every skill is equally portable:

- **`git-workflows`** is plain git and needs nothing else. `git-stacked-pr-rebase` wants
  git 2.38+ and, optionally, the `gh` CLI to read and retarget PR bases.
- **`speckit-orchestrator`** skills need Spec Kit installed, plus `git` and the `gh` CLI.
  `speckit-sprint-orchestrator` also needs an agent that can spawn subagents, and
  ticket-driven mode in `speckit-multi-implement` needs an issue-tracker MCP server
  configured in your agent.

---

## Layout

```text
.claude-plugin/marketplace.json    # lists every plugin below
plugins/
  <plugin>/
    .claude-plugin/plugin.json     # plugin manifest
    skills/<skill>/SKILL.md        # one directory per skill
```

A plugin's own README documents its prerequisites, configuration, and design
principles. `speckit-orchestrator` in particular **requires Spec Kit installed
separately** — it orchestrates that pipeline rather than bundling it.

## License

MIT — see [LICENSE](LICENSE).
