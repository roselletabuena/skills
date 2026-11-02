---
name: git-undo-recovery
description: Recover from a git mistake - lost commits after `reset --hard`, a deleted branch, a commit made on the wrong branch, a bad merge or rebase, a dropped stash, a force-push that overwrote someone's work, files lost to `checkout .`, `restore` or `clean`. Use this whenever the user says they "messed up", "lost" or "deleted" commits, a branch, stash or changes, asks how to "undo" a merge, rebase, reset, commit or push, or wants something "back". It triages what is actually recoverable before running anything, saves the lost state to a named ref first, and prefers `reset --keep` to `--hard` so the repair cannot destroy the user's current work.
---

# Recovering from a git mistake

Git rarely deletes anything immediately. Commits that no branch points to stay in the
object database until garbage collection, and the reflog records where every branch and
`HEAD` used to be. The danger is the *second* mistake, made while repairing the first -
typically a `reset --hard` that wipes the work done since.

## 0. Stop, then look before you change anything

```bash
git status                       # is a merge/rebase/cherry-pick in progress? what is dirty?
git reflog -n 30                 # HEAD's recent positions, newest first
git branch -a -vv
```

Do not run `git gc`, `git prune`, `git reflog expire` or `git clean` while recovering.
Do not "start fresh" with `git reset --hard` or a re-clone: the lost state may exist only here.

If the lost commit is visible, **pin it before anything else**:

```bash
git branch rescue/<what-it-was> <sha>
```

A named branch cannot be garbage collected, so from this point the work is safe whatever
happens next.

## 1. Be honest about what can come back

| Lost | Recoverable? | How |
|---|---|---|
| Committed work (reset, rebase, amend, deleted branch) | **Yes** | Reflog, step 2. |
| Staged but never committed (`git add` ran, then `checkout .` / `restore` / `reset --hard`) | **Usually** - the file content is a dangling blob | `git fsck --lost-found`, step 3. |
| A dropped or cleared stash | **Yes** | Step 3. |
| Edits that were never staged or committed, overwritten by `reset --hard`, `checkout`, `restore` | **No** - git never saw them | Check editor local history, IDE "local history", OS file history or backups. |
| Untracked files removed by `git clean` | **No** | Same as above. |

Say plainly which row the situation is in. Promising a recovery that is impossible wastes
the user's time while the real source (an editor's local history) goes stale.

## 2. Find the lost commit

The reflog is per-clone and shows each position as `HEAD@{n}`:

```bash
git reflog                                   # find the entry just before the mistake
git log --oneline rescue/<name>              # confirm it is the work the user means
git show --stat <sha>
```

A branch has its own reflog too: `git reflog show <branch>`, and `<branch>@{1}` is where it
was one move ago. A *deleted* branch no longer has one, but `HEAD`'s reflog still shows
`checkout: moving from <name> to ...`; the commit just before that is its tip.

Then restore, choosing the least destructive way:

```bash
git branch <name> <sha>                      # bring a deleted branch back
git merge --ff-only <sha>                    # move the current branch forward to it
git reset --keep <sha>                       # move the branch AND keep local edits;
                                             #   refuses, rather than overwrites, on overlap
```

Use `--keep`, not `--hard`. If `--keep` refuses, that is it telling you the move would
overwrite the user's uncommitted edits to the same file; stash or commit them first.

## 3. Dangling blobs, commits and stashes

```bash
git fsck --lost-found                         # dangling commits and blobs; blobs land in .git/lost-found/other/
git fsck --unreachable --no-reflogs | grep commit
git log --no-walk --format='%h %ci %s' <sha>...   # identify candidates by date and subject
```

- **Dropped stash**: `git stash drop` prints the SHA when it runs; if it is still in
  the terminal, `git stash apply <sha>`. Otherwise stash commits show up in `fsck` as
  unreachable commits with a subject starting `WIP on` or `On <branch>:`.
- **Lost staged file**: open the dangling blobs in `.git/lost-found/other/` and match by content.

## 4. Common situations

**Committed on the wrong branch** (not yet pushed):

```bash
git branch <right-branch>                    # a new branch at the current commit, keeping the work
git reset --keep <the-commit-before-yours>   # move the wrong branch back (e.g. origin/main)
git switch <right-branch>
```

**Bad merge, not pushed.** If it is still in progress, `git merge --abort`. If it is done,
`git reset --keep ORIG_HEAD` (git set `ORIG_HEAD` to the pre-merge tip, until the next
reset/merge/rebase overwrites it; use the reflog if it has).

**Bad merge, already pushed.** Do not rewrite shared history. `git revert -m 1 <merge-sha>`.
Note that merging the same branch again later will bring nothing back, since git considers
it landed; revert the revert first.

**Rebase went wrong.** In progress: `git rebase --abort`. Finished: the pre-rebase tip is
`<branch>@{1}` in the reflog; check it, then `git reset --keep` to it.

**Rebase/merge/cherry-pick stuck mid-way.** `git <op> --abort` returns to the start. Prefer
it to hand-editing `.git` state.

**Commit pushed that should not have been** (shared branch): `git revert`, not reset and
force-push. If it contained a credential, rotating the credential comes first; the commit
cannot be un-published.

**Force-pushed over someone else's commits.** The remote has no reflog you can reach,
so look elsewhere, roughly in this order: the teammate's own clone (`git reflog` there);
your remote-tracking ref's reflog (`git reflog show origin/<branch>`) if you fetched before
the overwrite; the old head SHA in the PR timeline's "force-pushed" event, or CI run
logs. If you have a SHA, `git fetch origin <sha>` often works while the host still has the
object. Then `git branch rescue/<name> <sha>`, and restore the branch with a *normal*
push of a commit that includes it, after agreeing with the owner.

**`git checkout .` / `restore` / `reset --hard` ate changes.** Staged-before: step 3.
Never staged: not recoverable by git - go to the editor's local history.

## 5. Finish

1. Confirm the recovered state is what the user wanted: `git log --oneline`, `git diff`
   against what they expected, a build if it is cheap.
2. Leave the `rescue/*` branch in place and tell them it exists. Do not delete it unprompted.
3. Say what was recovered, what was not and why, and what to do differently
   (`reset --keep`, `push --force-with-lease`, `stash -u` before experiments).

## Guardrails

- **`reset --hard` and `clean -fd` are the commands that cause the unrecoverable losses.**
  Never use either as part of a repair without the user knowing what it will discard.
- **Reflog is not a backup.** It is local, it expires, and a fresh clone has none. When the
  stakes are high, pin a branch first.
- **Do not recover into the user's working branch until the lost state is pinned.**
- **Do not push the recovery** without being asked; a recovered branch is a local fix.
