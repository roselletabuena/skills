---
type: llm
focus: trace
weight: 1
---

If a test script was used, it exits 0 for good and 1 for bad and does not mark a commit bad merely because the build or the program failed to run (for example it uses exit 125 to skip). If no script was used, this criterion is satisfied only when the run bisected manually with correct good/bad marks.
