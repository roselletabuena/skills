# Atomic Commits

Splits working-tree changes into atomic, single-purpose git commits.

One skill, `git-atomic-commit`: it surveys what changed, groups it into logical
units, orders them so **every intermediate commit builds**, and writes messages that
match the repository's existing style.

The payoff is not tidiness. It is the three abilities a team loses when commits are
mixed: a reviewer can hold one idea in their head, a bad change can be reverted
without taking good changes with it, and `git bisect` can name the commit that
introduced a bug.

It triggers on any request to commit, split, separate, reorder or clean up commits —
and it handles partial staging without `git add -p`, which silently stages nothing in
non-interactive environments.

| Path | Contents |
| :--- | :--- |
| `skills/git-atomic-commit/SKILL.md` | The skill |
| `skills/git-atomic-commit/references/splitting-one-file.md` | Techniques for staging part of a file |
| `skills/git-atomic-commit/evals/` | Eval cases, each with a scaffold script and graders |

## Prerequisites

`git`. Nothing else.

## Installation

This plugin ships in the [`agent-skills`](../../) marketplace.

```bash
claude plugin marketplace add roselletabuena/skills
claude plugin install git-atomic-commit@agent-skills
```

To try it without installing:

```bash
claude --plugin-dir ./plugins/git-atomic-commit
```

### skills.sh and other agents

The skill is a standard `SKILL.md` folder, so it also installs through the open
[`skills`](https://github.com/vercel-labs/skills) CLI behind [skills.sh](https://skills.sh).
That works with Claude Code, Codex, Cursor, OpenCode and many other agents, not just
Claude Code:

```bash
npx skills add roselletabuena/skills --skill git-atomic-commit
```

It installs into the current project by default. Add `-g` to make it available across
projects, or `-a <agent>` to target one agent:

```bash
npx skills add roselletabuena/skills --skill git-atomic-commit -g
npx skills add roselletabuena/skills --skill git-atomic-commit -a claude-code
```

Update or remove it later with `npx skills update git-atomic-commit` and
`npx skills remove git-atomic-commit`.

This installs the skill only, not the plugin wrapper, so it is invoked as
`git-atomic-commit` rather than the plugin-namespaced `git-atomic-commit:git-atomic-commit`.

## License

MIT — see [LICENSE](LICENSE).
