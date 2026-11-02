---
name: git-conflict-resolution
description: Resolve git merge, rebase, cherry-pick, revert or stash-pop conflicts correctly - understand what each side was trying to do, combine them rather than pick one, check the result builds, and continue the operation. Use this whenever the user hits a merge conflict, sees `<<<<<<<` markers, "CONFLICT (content)", "both modified", "deleted by us/them", or asks to "fix the conflicts", "finish the rebase" or "resolve and continue". Also use it before running `--ours`, `--theirs`, `-X ours` or `-X theirs`, because during a rebase those mean the opposite of what they appear to, and taking one side wholesale silently discards someone's work.
---

# Resolving conflicts

A conflict means git found two changes to the same place and refuses to guess. A resolution
is a *decision about intent*, and the safe default is to keep both sides' intent. Resolving
by deleting one side makes the markers disappear and the problem worse: the build still
passes, and a colleague's change is gone.

## 1. Know which operation you are in - `ours` and `theirs` depend on it

```bash
git status                  # "rebase in progress" / "You have unmerged paths" / "cherry-pick in progress"
```

| Operation | `--ours` / `HEAD` side | `--theirs` side |
|---|---|---|
| `merge` | the branch you are on | the branch being merged in |
| `rebase` | **the branch you are rebasing onto** (upstream) | **your own commit being replayed** |
| `cherry-pick`, `revert`, `stash pop` | the branch you are on | the commit being applied |

The rebase row is the trap. During `git rebase main`, "ours" is `main` and "theirs" is the
user's own work, the reverse of a merge. `git checkout --theirs file` in a rebase keeps
*your* change and discards upstream's. Re-read this table before using either flag.

## 2. See the whole conflict, not just the markers

```bash
git diff --name-only --diff-filter=U        # unmerged files
git status                                   # the type: both modified / deleted by us / both added
git config merge.conflictStyle zdiff3        # show the common ancestor too (git 2.35+; use diff3 on older)
git checkout --conflict=zdiff3 -- <file>     # re-render ONE file with the base shown (discards edits already made to it)
```

With the base visible, the markers have three parts: your side, the original, their side.
Most apparent conflicts become obvious when you can see what each side *changed from*.

To understand why each side changed:

```bash
git log --merge -p -- <file>                 # commits from both sides touching the file (merge or rebase in progress)
git show REBASE_HEAD                          # during a rebase: the commit being replayed
git show :1:<file>  :2:<file>  :3:<file>     # base, "ours", "theirs" as whole files
```

Read the commit messages. A resolution you cannot explain in a sentence per side is a guess.

## 3. Resolve by combining

- **Both sides edited the same lines for different reasons** - write the version that does
  both. For example, one side added a `tax_rate` parameter and the other a `discount`
  parameter: the resolved function takes both and applies both.
- **One side moved or renamed, the other edited** - apply the edit at the new location.
  Do not keep the old file and the new one.
- **Deleted by one side, modified by the other** - this is a real decision, not a mechanical
  one. Find out why it was deleted; if the modification still matters, it must be carried
  over, otherwise the deletion wins. Ask the user if unclear.
- **Generated files and lockfiles** (`package-lock.json`, `poetry.lock`, `go.sum`, snapshots,
  compiled output) - do not hand-merge. Take either side, then regenerate with the tool
  (`npm install`, `poetry lock`, `go mod tidy`, the snapshot command).
- **Binary files** - there is no merge; pick a side deliberately (mind the table above)
  and say so.

Text can merge cleanly and still be wrong: if one side renamed a function and the other
added a call to the old name, git sees no conflict. That is why step 4 includes building.

**Blanket flags hide decisions.** `git checkout --ours .`, `-X ours` / `-X theirs` (which
resolve every *conflicting* hunk toward one side) and `-s ours` (which discards the other
branch entirely) each throw away work without looking at it. Use them only when the user
asked for exactly that and knows what is being dropped.

## 4. Verify, then continue

```bash
git diff --check                              # fails on leftover conflict markers and whitespace errors
grep -rnE '^(<<<<<<<|=======|>>>>>>>)' .      # belt and braces, in files git does not diff-check
# build and run the fastest relevant tests
git add <resolved-files>
```

Continue with the matching command. Add `GIT_EDITOR=true` where an editor would open, since
an editor hangs in a non-interactive shell:

```bash
git merge --continue            # or: git commit --no-edit
GIT_EDITOR=true git rebase --continue
GIT_EDITOR=true git cherry-pick --continue
```

A rebase replays commits one by one, so it can stop again on the next commit. Repeat
the loop. Resolve at the earliest commit where a conflict appears; later ones may be
the same conflict replaying.

If tests fail after resolving, the failure is information about the resolution. Do not
continue past it and do not "fix" it by editing tests until you know which side's behavior
the test is protecting.

## 5. When to stop and ask

Stop rather than guess when:

- both sides changed business logic in incompatible ways (two different tax rules, two
  different retry policies);
- you cannot say in a sentence why each side made its change;
- the resolution makes a test fail and the cause is not clear.

State the two intents, say what you would choose and why, and let the user decide. Everything
before `--continue` is reversible: `git merge --abort`, `git rebase --abort`,
`git cherry-pick --abort` return the tree to where it started.

## Repeated conflicts

For a long rebase where the same conflict recurs, or a branch that is repeatedly merged
and abandoned:

```bash
git config rerere.enabled true      # records each resolution and replays it next time
git rerere diff                      # what it recorded
git rerere forget-path <file>        # discard a recorded resolution that was wrong
```

`rerere` reapplies a resolution *without asking*, so a bad one propagates. After a
rerere-resolved conflict, still check the result.

When a branch is long-lived and far behind, merging the trunk in once usually means one
round of conflicts; rebasing replays them per commit. That choice is the user's.

## Guardrails

- **Never resolve by taking one side wholesale to make conflicts go away.** The other side is somebody's work.
- **Do not abort a rebase the user asked you to finish** just because it is tedious; abort only if it is going wrong, and say so.
- **Do not push** after resolving unless asked. A rebase needs a force-push; follow `git-safe-history-rewrite`.
- **Report each conflicted file**: what both sides did, what you kept, and anything you could not verify.
