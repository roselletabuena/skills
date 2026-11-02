# Git Workflows

Skills for the parts of git where doing it the obvious way quietly goes wrong.

| Skill | What it does |
| :--- | :--- |
| `git-atomic-commit` | Splits working-tree changes into atomic, single-purpose commits: groups them into logical units, orders them so **every intermediate commit builds**, and writes messages that match the repository's existing style. Handles partial staging without `git add -p`, which silently stages nothing in non-interactive environments. |
| `git-stacked-pr-rebase` | Rebases a stack of dependent branches and PRs after something underneath changes: the bottom PR was squash-merged, a lower branch was amended, or the trunk moved. Pins the old tips, uses `git rebase --update-refs --onto`, verifies with `range-diff`, and publishes with an explicit `--force-with-lease`. |

The two work together: atomic commits are what make a stack easy to review and cheap to
rebase.

## Why these exist

**Atomic commits.** The payoff is not tidiness. It is the three abilities a team loses
when commits are mixed: a reviewer can hold one idea in their head, a bad change can be
reverted without taking good changes with it, and `git bisect` can name the commit that
introduced a bug.

**Stacked PR rebases.** After a squash-merge, a plain `git rebase main` replays the merged
PR's old commits on top of their own squashed copy and conflicts on work that already
landed. The fix is `--onto` with the old parent tip, which has to be captured *before*
anything moves. A branch checked out in another worktree is also skipped by
`--update-refs` with no error. The skill covers both.

| Path | Contents |
| :--- | :--- |
| `skills/git-atomic-commit/SKILL.md` | The atomic-commit skill |
| `skills/git-atomic-commit/references/splitting-one-file.md` | Techniques for staging part of a file |
| `skills/git-atomic-commit/evals/` | Eval cases for `git-atomic-commit`, each with a scaffold script and graders |
| `skills/git-stacked-pr-rebase/SKILL.md` | The stacked-PR rebase skill |

## Prerequisites

`git`. `git-stacked-pr-rebase` needs git 2.38 or newer for `--update-refs` (it describes a
branch-by-branch fallback for older versions) and uses the `gh` CLI to read PR base
branches and retarget them; it still works without `gh` if you tell it the stack order.

## Installation

This plugin ships in the [`agent-skills`](../../) marketplace.

```bash
claude plugin marketplace add roselletabuena/skills
claude plugin install git-workflows@agent-skills
```

To try it without installing:

```bash
claude --plugin-dir ./plugins/git-workflows
```

### skills.sh and other agents

The skills are standard `SKILL.md` folders, so they also install through the open
[`skills`](https://github.com/vercel-labs/skills) CLI behind [skills.sh](https://skills.sh).
That works with Claude Code, Codex, Cursor, OpenCode and many other agents, not just
Claude Code:

```bash
npx skills add roselletabuena/skills --skill git-atomic-commit
npx skills add roselletabuena/skills --skill git-stacked-pr-rebase
```

They install into the current project by default. Add `-g` to make them available across
projects, or `-a <agent>` to target one agent:

```bash
npx skills add roselletabuena/skills --skill git-stacked-pr-rebase -g
npx skills add roselletabuena/skills --skill git-stacked-pr-rebase -a claude-code
```

Update or remove one later with `npx skills update <skill>` and `npx skills remove <skill>`.

This installs the skill only, not the plugin wrapper, so it is invoked as
`git-stacked-pr-rebase` rather than the plugin-namespaced `git-workflows:git-stacked-pr-rebase`.

## Upgrading from `git-atomic-commit`

This plugin was previously published as `git-atomic-commit`. The skill of that name is
unchanged and is still part of this plugin. If you installed the old plugin, switch over:

```bash
claude plugin uninstall git-atomic-commit@agent-skills
claude plugin install git-workflows@agent-skills
```

Installs made through `npx skills` are unaffected.

## License

MIT — see [LICENSE](LICENSE).
