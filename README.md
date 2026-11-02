# agent-skills

A Claude Code **plugin marketplace**. Each plugin here is a self-contained bundle of
skills that can be installed on its own.

| Plugin | What it does |
| :--- | :--- |
| [**speckit-orchestrator**](plugins/speckit-orchestrator/) | An orchestration layer for [GitHub Spec Kit](https://github.com/github/spec-kit): drives one feature end to end in an isolated git worktree behind an 8-artifact gate, batch-executes tickets with failure isolation, and runs autonomous sprints via context-isolated subagents. Five skills. |
| [**git-atomic-commit**](plugins/git-atomic-commit/) | Splits working-tree changes into atomic, single-purpose commits — grouped into logical units, ordered so each commit builds, messaged to match the repository's existing style. Includes an eval suite. |

---

## Installation

Add the marketplace once, then install whichever plugins you want:

```bash
claude plugin marketplace add <owner>/agent-skills
claude plugin install speckit-orchestrator@agent-skills
claude plugin install git-atomic-commit@agent-skills
```

Or from inside a session: `/plugin marketplace add <owner>/agent-skills`, then install
from the `/plugin` panel.

To try one without installing, point Claude Code straight at its directory:

```bash
claude --plugin-dir ./plugins/git-atomic-commit
```

For another agent harness, copy the plugin's `skills/` directory into wherever that
harness discovers skills.

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
