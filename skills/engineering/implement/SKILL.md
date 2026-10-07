---
name: implement
description: "Implement work from a specification or tickets, then test, review, commit, push, and prepare a pull request."
metadata:
  opencode/autoinvoke: "false"
---

# Implement

Implement the work described by the user in the specification or tickets, following the repository instructions and acceptance criteria.

Resolve referenced skills through the current harness's available-skills catalog and read their `SKILL.md` before following them. In Codex, apply those instructions directly with the available tools. If a referenced skill is unavailable, perform its step directly and report that fallback.

1. Implement the requested behavior. Use the `tdd` skill where possible, at pre-agreed seams.
2. Run the repository's typecheck and affected test files regularly during implementation. Run the full test suite once implementation is complete. Report unavailable checks or existing failures accurately.
3. Use the `code-review` skill to review the completed changes against the specification and repository standards. Address findings and rerun checks affected by any fixes.
4. Commit the task's changes and push to the current branch, unless the user's instructions or repository rules specify another delivery path. Use the `pr` skill to prepare and open the pull request.

Report the implemented behavior, validation results, and pull request URL, including any unresolved findings or skipped checks.
