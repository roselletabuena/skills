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
| [**git-atomic-commit**](plugins/git-atomic-commit/) | Splits working-tree changes into atomic, single-purpose commits — grouped into logical units, ordered so each commit builds, messaged to match the repository's existing style. Includes an eval suite. |

---

## Installation

### Claude Code

Add the marketplace once, then install whichever plugins you want:

```bash
claude plugin marketplace add roselletabuena/skills
claude plugin install speckit-orchestrator@agent-skills
claude plugin install git-atomic-commit@agent-skills
```

Or from inside a session: `/plugin marketplace add roselletabuena/skills`, then install
from the `/plugin` panel.

To try one without installing, point Claude Code straight at its directory:

```bash
claude --plugin-dir ./plugins/git-atomic-commit
```

### Other agents

Copy a skill folder (for example `plugins/git-atomic-commit/skills/git-atomic-commit/`)
into the directory your agent discovers skills from. For Google Antigravity that is
`<workspace>/.agent/skills/` for one project or `~/.gemini/antigravity/skills/` for all
projects; restart the agent session afterwards so it re-detects them. Check your agent's
docs for its own path.

Not every skill is equally portable:

- **`git-atomic-commit`** is plain git and needs nothing else.
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
