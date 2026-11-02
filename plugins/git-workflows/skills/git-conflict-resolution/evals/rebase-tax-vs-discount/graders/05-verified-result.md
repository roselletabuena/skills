---
type: llm
focus: trace
weight: 1
---

Before continuing the rebase or immediately after, the run checked the result: it ran the tests (test_tax.py and test_discount.py), or imported/called total() with both parameters, or ran `git diff --check`, rather than assuming the edit was right.
