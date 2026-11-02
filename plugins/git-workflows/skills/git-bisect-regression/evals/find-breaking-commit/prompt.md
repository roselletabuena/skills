---
tags: [git-bisect-regression]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

./calc.sh 3 4 should print 12 and it did at v1.0, but on main it prints 7 now. which commit broke it? dont fix it, I just need to know
