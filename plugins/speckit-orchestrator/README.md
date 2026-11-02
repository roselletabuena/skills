# Spec Kit Orchestrator

An orchestration layer for [GitHub Spec Kit](https://github.com/github/spec-kit).

Spec Kit gives you the pipeline primitives — specify, clarify, plan, tasks, implement. This plugin adds the **conductors** that run them end to end: isolated git worktrees, a mandatory artifact gate, batch ticket execution with failure isolation, and context-isolated subagent sprints.

> [!IMPORTANT]
> **This plugin does not bundle Spec Kit.** It orchestrates it. You must install Spec Kit
> separately — see [Prerequisites](#prerequisites). Without it, these skills have nothing
> to conduct.

---

## Skills

| Skill | What it does |
| :--- | :--- |
| **`speckit-workflow`** | Drives **one** feature end to end in an isolated git worktree: worktree → spec → clarify → checklist → plan → tasks → analyze → TDD implement → converge → review → PR. Enforces an 8-artifact gate before any code is written. |
| **`speckit-multi-implement`** | Drives **many** tickets through the same lifecycle, with per-ticket state tracking and failure isolation, so one failing story never blocks the independent ones behind it. |
| **`speckit-sprint-orchestrator`** | Runs an autonomous sprint by delegating prioritization and each ticket to **context-isolated subagents**, keeping the coordinator's context thin. |
| **`pr-creator`** | Rebases onto the latest base branch, enforces branch naming, and opens an audit-ready PR via `gh`. |
| **`story-prioritizer`** | Scores a backlog on five weighted factors and partitions it into collision-free parallel workstreams. Read-only. |

`speckit-workflow` and `speckit-multi-implement` work standalone. `speckit-sprint-orchestrator` composes all five.

---

## Prerequisites

### Required

**1. Spec Kit pipeline skills.** The orchestrators invoke `speckit-specify`, `speckit-clarify`, `speckit-checklist`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-implement`, and `speckit-converge`. Install them with the Spec Kit CLI in your project root:

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init --here
```

This also creates the `.specify/` directory the orchestrators expect.

**2. Tooling.** `git` with worktree support, and the [GitHub CLI](https://cli.github.com/) authenticated (`gh auth status`).

### Optional

Each of these unlocks a gate; when absent, that gate is **skipped with a note in the final report** rather than failing the run:

| Skill | Unlocks |
| :--- | :--- |
| `code-review`, `code-review-and-quality` | The automated review gate (spec fidelity, standards, five quality axes) |
| `constitution-check` | Project-principle compliance checks |
| `env-validator` | Configuration and secret-access discipline |
| `graphify-auto-sync` | Knowledge-graph refresh after a feature lands |
| `atomic-commit`, `tdd` | Stricter commit decomposition and red-green-refactor discipline |

An **issue-tracker MCP server** (Atlassian for Jira, or the GitHub MCP server for Issues) enables ticket-driven mode. Without one, the skills run in **file-driven mode**: they accept plain feature descriptions or a `priority_queue.json` and skip every tracker sync step.

---

## Installation

This plugin ships in the [`agent-skills`](../../) marketplace.

```bash
claude plugin marketplace add <owner>/agent-skills
claude plugin install speckit-orchestrator@agent-skills
```

Or from inside a session: `/plugin marketplace add <owner>/agent-skills`, then install from the `/plugin` panel.

To try it without installing, point Claude Code straight at this directory:

```bash
claude --plugin-dir ./plugins/speckit-orchestrator
```

For another agent harness, copy this plugin's `skills/` directory into wherever it discovers skills.

---

## Configuration

Create `.speckit/orchestrator.json` in your project root. **Every key is optional** — the documented default applies when a key or the whole file is absent.

```json
{
  "baseBranch": "main",
  "ticketPrefix": "PROJ",
  "trackerBaseUrl": "https://your-org.atlassian.net/browse",
  "specRoot": "specs",
  "featureRoot": "src",
  "worktreeRoot": ".worktrees",
  "verify": {
    "typecheck": "npm run typecheck",
    "lint": "npm run lint",
    "test": "npm run test"
  },
  "scaffold": null,
  "envFiles": [".env.local"],
  "linkNodeModules": true,
  "tracker": {
    "inProgressState": "In Progress",
    "completeState": "In Review",
    "autoClose": false
  },
  "maxConcurrent": 2
}
```

| Key | Default | Notes |
| :--- | :--- | :--- |
| `baseBranch` | `main` | The branch worktrees fork from and PRs target |
| `ticketPrefix` | *unset* | Unset enables **ticketless mode** — no keys in branches or titles, no tracker sync |
| `trackerBaseUrl` | *unset* | Base URL for rendering ticket links |
| `specRoot` | `specs` | Where the 8 canonical artifacts are written |
| `featureRoot` | `src` | Reporting and review scoping only; no layout is assumed |
| `worktreeRoot` | `.worktrees` | Add this to `.gitignore` |
| `verify.*` | auto-detected | Probed from `package.json` scripts; a gate with no command is **skipped, never guessed** |
| `scaffold` | `null` | Optional command or skill to create a feature skeleton |
| `maxConcurrent` | `2` | Parallel worker cap for the sprint orchestrator |

### Not a Node project?

Set the three `verify` commands to whatever your stack uses — `cargo clippy`, `mypy .`, `go test ./...`, `pytest`. Nothing outside those keys and `linkNodeModules` assumes JavaScript.

---

## Usage

```text
Run the speckit workflow for a dark-mode toggle in the settings panel
```

```text
Use speckit-multi-implement for PROJ-38, PROJ-25, and PROJ-20
```

```text
Run the sprint orchestrator on Sprint 2
```

---

## Design Principles

These are the opinions baked into the skills. They are the reason the plugin exists, and the thing to fork if you disagree.

1. **The 8-artifact gate is mandatory.** `spec.md`, `research.md`, `data-model.md`, `contracts/`, `checklists/requirements.md`, `plan.md`, `quickstart.md`, `tasks.md` — all eight exist before a line of implementation is written. Skipping ahead to code is the exact failure this pipeline prevents.

2. **One feature, one worktree.** Features never share a checkout. Parallel work cannot clobber another branch's staging area or build cache.

3. **Context isolation over context size.** A coordinator that reads every test log reasons worse than one that reads receipts. Heavy work is delegated; only compact receipts cross the boundary.

4. **Skipped is not passed.** A gate with no configured command is reported as SKIPPED, with the reason. Checkboxes are never pre-checked, and a verification table never claims a run that did not happen.

5. **Never invent project conventions.** A missing script is a skipped gate, not a guessed command. When a convention is neither configured nor detectable, ask once and offer to persist the answer.

6. **Serialize when uncertain.** A mis-parallelized pair of tickets costs a painful rebase. An over-serialized pair costs a little wall-clock time.

---

## Relationship to Spec Kit

The `speckit-*` pipeline skills are authored and maintained by the [github/spec-kit](https://github.com/github/spec-kit) project and are **not redistributed here**. This plugin contains only the orchestration layer built on top of them. Install Spec Kit from upstream to get the pipeline, and consult its documentation for the behavior of the individual phases.

## License

MIT — see [LICENSE](LICENSE).
