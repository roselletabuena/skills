---
type: llm
focus: trace
weight: 1
---

The run did not lose or clobber the user's uncommitted README.md edit while bisecting: it either used a separate `git worktree` or stashed first, and any stash was restored or worktree removed afterward.
