# Splitting two logical changes inside one file

Read this only after Level 1 (whole-file staging) and Level 2 (`git stash push -- <path>`)
have been ruled out, which is most of the time. Reach for it when a single file
genuinely holds two independent changes - a typo fix that landed in the middle of a
feature edit, a debug line left beside real logic, two unrelated bug fixes in one module.

Both methods below were verified to work non-interactively. Pick by situation:

| Method | Use when | Risk |
|---|---|---|
| **A: slice the patch** | Changes are a few lines, far apart in the file | Patch may not apply; nothing is lost if it fails |
| **B: rebuild the content** | Patch slicing failed, or the changes are large or interleaved | Destroys work if the backup step is skipped |

## Why not `git add -p`

It is interactive, so with no TTY it prints the first hunk, hits EOF, stages nothing,
and **exits 0**. The success code is what makes this dangerous: a check of the exit
status will pass while the index is still empty. The same holds for `git add -i`,
`git commit -p` and `git checkout -p`. Always confirm with `git diff --cached` rather
than trusting an exit code.

## Method A - slice the patch and apply it to the index

The idea: write the file's diff to a patch, delete the hunks you do not want, and
apply what remains to the index only. The working tree keeps all the changes, so the
leftover shows up as the next commit.

```bash
# 1. If the file is untracked, git diff shows nothing for it - mark it first.
#    This stages no content, it only makes the file visible to git diff.
git add -N path/to/file.py

# 2. Capture the full diff for just that file.
git diff -- path/to/file.py > /tmp/full.patch

# 3. Edit /tmp/full.patch down to the hunks you want in THIS commit.
#    Keep all four header lines (diff --git, index, ---, +++) intact, then keep
#    only the chosen @@ hunks and drop the rest.

# 4. Apply to the index only. --recount lets git recompute the line counts in the
#    @@ header, so a hand-edited patch still applies.
git apply --cached --recount /tmp/full.patch

# 5. Verify the index holds only what you intended - never skip this.
git diff --cached        # what will be committed
git diff                 # what is left for the next commit

git commit -m "..."
```

Then commit the remainder normally (`git add path/to/file.py && git commit`).

**Keeping the headers matters.** The four lines above the first `@@` tell git which
file and blob the patch applies to. A hunk without them applies to nothing.

**If `git apply` fails**, do not start loosening flags blindly. `--recount` already
handles bad line counts. The usual real causes are a corrupted header, overlapping
context between adjacent hunks, or line-ending mismatch - on Windows, `core.autocrlf`
can make the patch text disagree with the index. Nothing has changed at this point,
so switch to Method B rather than retrying.

**Adjacent hunks are the common trap.** If the two changes are only a few lines apart,
their context lines overlap and slicing produces a patch that cannot apply cleanly.
Generating the diff with more context (`git diff -U5`) sometimes separates them; if the
changes are genuinely interleaved, Method B is the right tool.

## Method B - rebuild the file content

No patch mechanics: save the final content, return the file to its committed state,
re-apply one change, commit, then restore the full content and commit the rest. More
steps, but each step is an ordinary file edit, so there is less to go wrong.

```bash
# 1. Save the finished content FIRST, and confirm the copy exists.
cp path/to/file.py /tmp/file.py.full
test -s /tmp/file.py.full || echo "BACKUP FAILED - stop here"

# 2. Return the file to its committed state. This discards the working-tree
#    changes, which is why step 1 must be verified before running it.
git checkout -- path/to/file.py

# 3. Re-apply ONLY the first logical change (a normal edit), then commit it.
git add path/to/file.py
git commit -m "..."

# 4. Restore the full content - this brings back the second change.
cp /tmp/file.py.full path/to/file.py
git add path/to/file.py
git commit -m "..."

# 5. Clean up and confirm nothing is left behind.
rm /tmp/file.py.full
git status --porcelain
```

**Step 1 is the whole safety story.** Between step 2 and step 4 the only copy of the
user's second change is the backup file. `git checkout --` discards uncommitted work
with no reflog entry and no way back, so verify the backup before running it, and keep
the backup outside the repository so it is never caught by a later `git add`.

Put backups in a temp or scratch directory rather than next to the file. A `file.py.bak`
inside the repo is easy to commit by accident, which turns a tidy split into a messy one.

## Verifying the result

After either method, check that the split actually came out as intended:

```bash
git show --stat HEAD~1 && git show --stat HEAD    # each commit's footprint
git show --unified=0 HEAD~1 | grep '^[-+][^-+]'   # the exact lines in each
git status --porcelain                            # anything left over
```

If the repo has a fast test or lint command and the split was non-trivial, it is worth
confirming the intermediate state built too - that is the property bisect depends on.
Checking out the earlier commit in a scratch worktree (`git worktree add`) tests this
without disturbing the user's tree.
