## Ticket

- **Issue**: [{{TICKET_KEY}}]({{TRACKER_BASE_URL}}/{{TICKET_KEY}})
- **Issue type**: {{ISSUE_TYPE}}
- **Estimate**: {{ESTIMATE}}
- **Parent epic**: {{PARENT_EPIC}}

---

## Executive summary

{{SUMMARY_DESCRIPTION}}

---

## Key architectural and code changes

- **Module / feature slice**: `{{FEATURE_SLICE}}`
- **Key changes**:
{{KEY_CHANGES_BULLETS}}

---

## Testing and verification

- [ ] **Unit and integration tests**: `{{TEST_COMMAND}}` ({{TEST_PASS_COUNT}} passing)
- [ ] **Typecheck**: `{{TYPECHECK_COMMAND}}` (0 errors)
- [ ] **Lint**: `{{LINT_COMMAND}}` (0 warnings)

```text
{{TEST_OUTPUT_SNIPPET}}
```

> Check a box only when that gate actually ran and passed. For a skipped gate, leave it
> unchecked and name the reason.

---

## Code review and quality audit

- [ ] **Spec axis**: implementation matches `spec.md` acceptance criteria and invariants — no omissions, no scope creep.
- [ ] **Standards axis**: conforms to this project's documented standards and the Fowler code-smell baseline.
- [ ] **Quality axes**: Correctness, Readability, Architecture, Security, Performance.
- **Review summary**: {{REVIEW_SUMMARY}}

---

## Project standards checklist

<!--
  Replace these with the host project's own principles. Each line should name a rule a
  reviewer can actually verify from the diff.
-->

- [ ] **Architecture**: changes stay within their intended module boundary.
- [ ] **Security and authorization**: protected paths verify the session; inputs validated at the boundary.
- [ ] **Zero regressions**: all pre-existing suites still pass.
- [ ] **Configuration discipline**: no raw environment access bypassing the validated config module.
- [ ] **Accessibility**: semantic markup, sufficient color contrast, keyboard navigation.
- [ ] **Atomic commits**: single-purpose, bisectable Conventional Commits.

---

## Visual evidence

{{VISUAL_EVIDENCE_OR_NOTE}}
