---
name: git-bisect-regression
description: Find which commit introduced a bug or behavior change using `git bisect`. Use this whenever the user says something "used to work", "worked last week", "stopped working", "broke at some point", asks "which commit broke this", "when did this start", "find the regression" or "who introduced this" - and also for finding the commit that fixed something or made it slow. It sets up a safe place to bisect (a dirty working tree blocks checkouts), writes a deterministic test script with the right exit codes, verifies both endpoints first, handles untestable commits and flaky tests, and always resets afterwards.
---

# Bisecting a regression

`git bisect` binary-searches history: given one commit where the behavior was right and one
where it is wrong, it checks out the midpoint, you say good or bad, and it halves the range
again. A thousand commits take about ten steps. It is only trustworthy if the good/bad
verdicts are, so most of the skill is in making the test reliable and the tree safe.

## 1. Preconditions

**Pin the two endpoints.** *Bad* is usually `HEAD`. *Good* needs a real commit the user
believes worked: a release tag, a known deploy, a date.

```bash
git log --oneline --since="3 weeks ago" | tail -1      # by date
git describe --tags --abbrev=0                          # latest tag
git log -1 --format=%H v1.0                             # a tag to SHA
```

If the user is unsure, take an older commit, not a newer one. A too-old good costs a step or
two; a too-new one makes bisect land on the wrong commit or complain that "bad" is
older than "good".

**Protect uncommitted work.** Bisect checks out many old commits, and checkout refuses
(or carries edits into the wrong version) if the tree is dirty. Either:

```bash
git worktree add --detach ../bisect-scratch HEAD    # best: leaves the user's tree untouched
cd ../bisect-scratch
```

or, if a worktree is awkward (dependencies installed per directory):

```bash
git stash push --include-untracked -m "pre-bisect"   # and git stash pop at the end
```

Whichever you choose, restore it at the end. The user's uncommitted work being intact when
you finish is part of the job.

## 2. Write the test as a script

The script is what makes every verdict repeatable. Put it **outside the repository** (the
scratchpad, `/tmp`), because old commits may not contain it and checkouts must not touch it.

Exit codes tell bisect what happened:

| Exit | Meaning |
|---|---|
| `0` | good |
| `1`-`127` except `125` | bad |
| `125` | **cannot test this commit - skip it** (does not build, dependency missing) |
| `128`+ | abort the whole bisect |

```bash
#!/usr/bin/env bash
# bisect-test.sh
make build >/dev/null 2>&1 || exit 125      # a broken build says nothing about the bug: SKIP, don't mark bad
out=$(./calc.sh 3 4) || exit 125            # the thing itself failed to run: also unknown
[ "$out" = "12" ] && exit 0 || exit 1       # the actual check
```

The common mistake is letting a build failure exit `1`, which marks every unbuildable
commit as "bad" and sends the search to the wrong place. Only the behavior under
investigation should return `1`.

A user-reported symptom ("the page is slow", "it crashes sometimes") must become something
a script can assert: an output compared to an expected value, a timing under a threshold, a
specific test selected with the test runner's filter. If you cannot make it deterministic,
fall back to manual `git bisect good` / `bad` and say it relies on a human judgment.

**Flaky tests.** A failure is evidence; a single pass is not. Run the check several times
and mark *good* only if all runs pass:

```bash
for i in 1 2 3 4 5; do ./check || exit 1; done; exit 0
```

## 3. Verify both endpoints, then run

Run the script on the supposedly-bad commit and the supposedly-good commit **before**
starting. If the "good" commit fails, the premise is wrong (or the test is), and bisect would
only produce a confident wrong answer.

```bash
git checkout -q <good> && bash /path/bisect-test.sh; echo "good-end exit: $?"   # expect 0
git checkout -q <bad>  && bash /path/bisect-test.sh; echo "bad-end exit:  $?"   # expect 1
git bisect start <bad> <good>
git bisect run bash /path/bisect-test.sh
```

`git bisect run` finishes by printing `<sha> is the first bad commit`. Then `git bisect log`
records what was decided.

Variations:

- **Merge-heavy history**: `git bisect start --first-parent <bad> <good>` first finds the
  offending merge on the mainline, then bisect inside it.
- **Not a bug** (when did it get slow / when was it fixed):
  `git bisect start --term-old=fast --term-new=slow` (any words), then use those terms in place of good/bad.
- **Untestable commits** that your script cannot detect: `git bisect skip` by hand. If many
  remain skipped, bisect can only narrow to a range and will say so.

## 4. Always clean up

```bash
git bisect reset            # returns to the branch you started on; do not skip it
cd - && git worktree remove ../bisect-scratch      # if you used a worktree
git stash pop               # if you used a stash
```

Leaving the repository mid-bisect on a detached `HEAD` is the usual way this goes wrong -
the user's next commit lands somewhere nobody expects.

Do not commit, fix or revert while bisecting. Finding the commit is the task; fixing is a
separate step the user may or may not want.

## 5. Confirm and report

A bisect result is a hypothesis until you have read it:

```bash
git show <sha>              # does the diff plausibly cause the symptom?
```

For extra confidence, check that the parent passes and the culprit fails by running the
script on `<sha>^` and `<sha>`. Report: the SHA, subject, author, date, **what in the diff
causes the symptom**, and how you tested it. If the culprit is a huge commit or a merge
commit, say that the answer is only as precise as the history, since a large mixed commit is
where atomic commits would have paid off (`git-atomic-commit`).

If the result says "there are only skipped commits left to test," report the candidate range
instead of picking one.

## Guardrails

- **Never bisect in the user's dirty working tree** without stashing or using a worktree.
- **Do not run a test with side effects against real services** across hundreds of commits.
- **Dependencies may differ per commit.** If a lockfile changed, install inside the script
  (or skip with `125` when that fails); a stale `node_modules` gives false verdicts.
- **A confident wrong answer is the main failure.** Verify the endpoints, make the script
  deterministic, and treat inconsistent results as a reason to stop.
