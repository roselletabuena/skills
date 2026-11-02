---
name: git-safe-history-rewrite
description: Rewrite git history without losing work or clobbering other people - amend, reset, squash, reorder, drop or edit commits, change a commit message, remove a commit from a branch, or force-push. Use this whenever the user asks to amend, squash, fixup, "undo the last commit", "get rid of that commit", "remove a commit from history", "clean up my commits before the PR", or to force-push; and whenever a task would end in `git push --force`. It decides whether rewriting is even appropriate (a commit others have pulled should be reverted, not erased), takes a recovery point first, avoids the interactive editors that hang in a non-interactive shell, and pushes with a lease instead of a bare force.
---

# Rewriting history safely

Every rewrite - `commit --amend`, `reset`, `rebase`, `filter-repo` - produces *new* commits
and moves a branch pointer off the old ones. That is harmless while nobody else has the old
commits, and destructive the moment someone does: their clone still has the old history,
and the next time they push or pull it comes back as duplicates or conflicts. So the first
question is never "how", it is "who else has these commits?"

## 1. Decide: rewrite or revert

```bash
git fetch --prune
git status --short --branch                  # ahead/behind, and dirty state
git branch -r --contains <commit>            # which remote branches already hold it
git log --oneline @{u}..HEAD                 # commits that exist only locally
```

| Where the commit lives | Do this |
|---|---|
| Local only, never pushed | Rewrite freely. |
| Pushed to a branch only this user works on (their PR branch) | Rewrite, then push with a lease (step 5). |
| On a shared or protected branch: `main`, `master`, `develop`, `release/*`, or anything with other people's commits on top | **Do not rewrite.** Use `git revert`. |
| Already released or deployed | `git revert`. A rewrite cannot un-deploy it. |

When the user says "get rid of that commit from main", they usually want its *effect*
gone, not its SHA. `git revert <sha>` does that, keeps history honest, and needs only an
ordinary push. For a merge commit, `git revert -m 1 <merge-sha>`. Say why you chose revert,
and if the user insists on erasing it from a shared branch, name who it will affect and
get an explicit yes first.

A revert conflicts when later commits edited the same lines - which is exactly the case
where commits were built on top of the bad one. Resolve it as any conflict (see
`git-conflict-resolution`): remove the bad change, keep the later work, then
`git revert --continue`.

One revert trap: after reverting a *merge*, merging the same branch again brings nothing
back, because git thinks those commits already landed. To re-land the work, revert the
revert first.

## 2. Take a recovery point before touching anything

```bash
git rev-parse HEAD                           # note it
git branch backup/<branch>-pre-rewrite       # a real ref, not just the reflog
```

The reflog also records where the branch was, but it is local to this clone, it expires
(90 days for reachable entries, 30 for unreachable by default), and `git gc` after
`reflog expire` ends it. A named backup branch costs nothing. Leave it in place until the
user has confirmed the result.

## 3. Pick the least destructive command

| Goal | Command | Notes |
|---|---|---|
| Fix the last commit's message or add a forgotten file | `git commit --amend` | `-m "..."` or `--no-edit` avoids opening an editor. |
| Uncommit but keep the changes staged | `git reset --soft HEAD~1` | |
| Uncommit and unstage, keep the files | `git reset --mixed HEAD~1` (the default) | |
| Move a branch back, refusing to lose local edits | `git reset --keep <commit>` | Aborts if it would overwrite uncommitted changes. Prefer this to `--hard`. |
| Throw away uncommitted work as well | `git reset --hard` | **Uncommitted work is not in the reflog and cannot be recovered.** Only after confirming nothing there is wanted; `git stash -u` first if unsure. |
| Discard changes to one file | `git restore <file>` | |
| Squash or fold fix-ups into earlier commits | `git commit --fixup=<sha>` then autosquash | See below. |
| Drop or reorder commits | `rebase -i` with a supplied todo | See below. |

**A failed pre-commit hook means no commit was made.** Running `git commit --amend` to
"retry" then modifies the *previous* commit, folding the new changes into the wrong one.
After a hook failure, fix the problem, re-stage, and make a normal new commit.

### Interactive rebase without an interactive editor

`git rebase -i` opens an editor, which hangs in a non-interactive shell. Do not rely on it.
Two ways that work:

```bash
# Fold fix-up commits into their targets - accept the todo git generates:
git commit --fixup=<target-sha>
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>

# Drop or reorder: write the todo yourself.
GIT_SEQUENCE_EDITOR="sed -i '/^pick <short-sha> /d'" git rebase -i <base>
```

`<base>` is the commit *before* the first one you want to change. If a rebase stops on a
conflict, resolve it, `git add`, then `GIT_EDITOR=true git rebase --continue`. If it goes
wrong, `git rebase --abort` returns to where it started.

## 4. Verify the rewrite changed what you meant it to

A message edit, reorder or squash should leave the final tree identical:

```bash
git diff backup/<branch>-pre-rewrite HEAD --stat      # empty = same content
git range-diff backup/<branch>-pre-rewrite...HEAD     # commit-by-commit comparison
```

If you *meant* to drop content, the diff should show exactly that content and nothing else.
Anything unexpected means restore from the backup and redo it.

## 5. Publish - only with the user's go-ahead

Pushing a rewrite is the outward-facing, hard-to-reverse step. Confirm first unless the
user already asked for the push.

```bash
git push --force-with-lease=<branch>:<expected-remote-sha> --force-if-includes origin <branch>
```

- **Never bare `--force`.** It overwrites whatever is on the remote, including a
  teammate's push you have not seen.
- **Name the expected SHA.** A plain `--force-with-lease` compares against your
  remote-tracking ref, and an IDE's background `git fetch` quietly updates that ref, so the
  lease then protects nothing. Use the SHA you saw in step 1 (`git rev-parse origin/<branch>`).
- `--force-if-includes` (git 2.30+) additionally refuses if the remote moved to something
  your local branch never integrated.
- **Never force-push `main`/`master`/`develop`/`release/*`.** If a hosting rule blocks it,
  that rule is correct; do not work around it.

After pushing, tell the user that anyone with the old branch checked out must reset to
the new one rather than pull, and that an open PR's review comments may lose their anchors.

## Guardrails

- **Signed commits lose their signatures** when rewritten; re-sign with `-S` or tell the user.
- **Do not rewrite commits another person authored** without asking, even on a feature branch.
- **Stacked branches above the rewritten one are now stale.** Use `git-stacked-pr-rebase`
  to restack them rather than rebasing each by hand.
- **A committed secret is not fixed by a rewrite.** Rotate the credential first; assume it
  is compromised.
- **Report plainly**: what the old tip was, what the new one is, where the backup ref is,
  and whether anything is unpushed. If revert was the right call, say that is what you did.
