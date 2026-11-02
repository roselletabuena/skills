# Agile Planning

Skills for turning an idea into work a team can plan, build and finish.

| Skill | What it does |
| :--- | :--- |
| `epic-creator` | Writes a well-formed epic: a problem statement and outcome hypothesis, success metrics with honest baselines, explicit scope and non-goals, epic-level acceptance criteria, and thin vertical-slice child stories that start with a walking skeleton. Declines to inflate a task or story into an epic, and can create the epic and its stories in Jira or GitHub Issues through a tracker MCP server once you approve the draft. |
| `user-story-creator` | Writes a well-formed user story with a fixed title format (`1.2 FE [Chatbot] Send a message and see the reply`), an As a / I want / so that statement, Given/When/Then acceptance criteria, and test cases traced back to every criterion. Links the story to its parent epic and to the stories it depends on, blocks, or relates to, checking direction, two-way consistency, cycles and ORDER before any link is made. Declines to write an oversized story as one ticket, and can create and link the stories in Jira or GitHub Issues once you approve the draft. |

## Why this exists

An epic is the point where a vague idea becomes a commitment, and most of the damage is
done there. Four failures account for most bad epics, and the skill is built around
preventing each one:

**A bucket instead of an outcome.** "Backend", "Tech debt" and "Q4 work" are labels, not
epics: nothing ever finishes them. The skill first checks that the work delivers one
outcome, splits into roughly 3-12 stories and can be declared done, and says so when a
request is really a task, a story or an initiative.

**A solution with no problem.** Epics that open with a feature list lock in an answer
before anyone has stated the question. The skill writes the problem, the users and a
testable outcome hypothesis first, and keeps the *how* out of the epic.

**Invented numbers.** A made-up baseline or target looks rigorous and gets planned around.
The skill writes "to be measured" for any figure you did not supply and lists the gap in
its report.

**Horizontal slicing.** "Build the schema", "build the API" and "build the UI" cannot be
demoed, tested or cut until all three land. The skill slices vertically, starts with a
walking skeleton, puts the riskiest assumption early and turns unknowns into time-boxed
spikes.

Stories have their own three failures, and `user-story-creator` addresses each:

**An unreadable backlog.** Titles written as sentences, endpoints or ticket keys cannot be
scanned or sorted. The skill uses one format, `ORDER STACK [FEATURE] Title`, with a
verb-first capability as the title. Short fixed-width tokens come first and free text last,
so a list sorted by title reads in delivery order. ORDER is a planned sequence rather than
an identity, so it is never renumbered; the tracker key stays the identity, and the stack is
also set as a native label or component. Where a team splits a slice into `FE` and `BE` stories, the two
share an ORDER and the slice counts as done only when both are.

**Criteria nobody can fail.** "Works correctly" cannot be tested, so the tests get written
afterwards from the code. The skill writes numbered Given/When/Then scenarios that cover the
happy, error and boundary paths, then derives test cases from them. Every criterion has a
test, and a test with no criterion is flagged as a missing criterion or scope creep.

**Links that lie.** A dependency written backwards, linked to a ticket that does not exist,
or closing a cycle sends work in the wrong order. The skill links only real items, states
every link from both sides, checks the direction, rejects cycles, and checks that ORDER
agrees with the dependencies before it creates anything.

| Path | Contents |
| :--- | :--- |
| `skills/epic-creator/SKILL.md` | The epic-creation skill, with two eval cases |
| `skills/epic-creator/templates/epic-template.md` | Epic template with `{{TOKEN}}` placeholders, used when the project has none of its own |
| `skills/epic-creator/references/slicing-patterns.md` | Story-splitting patterns and the anti-patterns to avoid |
| `skills/epic-creator/references/tracker-mapping.md` | How epic sections map to Jira and GitHub Issues fields |
| `skills/epic-creator/evals/` | Eval cases, each with a scaffold script and graders |
| `skills/user-story-creator/SKILL.md` | The user-story skill, with two eval cases |
| `skills/user-story-creator/templates/user-story-template.md` | Story template with `{{TOKEN}}` placeholders, used when the project has none of its own |
| `skills/user-story-creator/references/acceptance-criteria-and-test-cases.md` | Criteria patterns, test design techniques, and a worked example |
| `skills/user-story-creator/references/linking-stories.md` | Link types, direction and consistency checks, and Jira and GitHub mapping |
| `skills/user-story-creator/evals/` | Eval cases, each with a scaffold script and graders |

## Prerequisites

None to write an epic or a story. To create tickets and links, the skills need an
issue-tracker MCP server configured in your agent (for example the Atlassian server for Jira,
or the GitHub server for Issues). Without one they produce the markdown and stop there; they
never create tickets or links unprompted. The two skills work independently, so either can be
installed on its own.

## Installation

This plugin ships in the [`agent-skills`](../../) marketplace.

```bash
claude plugin marketplace add roselletabuena/skills
claude plugin install agile-planning@agent-skills
```

To try it without installing:

```bash
claude --plugin-dir ./plugins/agile-planning
```

### skills.sh and other agents

The skills are standard `SKILL.md` folders, so they also install through the open
[`skills`](https://github.com/vercel-labs/skills) CLI behind [skills.sh](https://skills.sh).
That works with Claude Code, Codex, Cursor, OpenCode and many other agents, not just
Claude Code:

```bash
npx skills add roselletabuena/skills --skill epic-creator
npx skills add roselletabuena/skills --skill user-story-creator
```

They install into the current project by default. Add `-g` to make them available across
projects, or `-a <agent>` to target one agent. Update or remove one later with
`npx skills update <skill>` and `npx skills remove <skill>`.

This installs the skill only, not the plugin wrapper, so it is invoked as `epic-creator`
rather than the plugin-namespaced `agile-planning:epic-creator`.

## License

MIT — see [LICENSE](LICENSE).
