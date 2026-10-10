---
name: pr
description: "Pull request writing. Use when preparing or opening a pull request for a branch."
---

# PR

Write a pull request description that a reviewer can trust without asking the
author anything. Every claim rests on **proof**:
- the diff;
- before and after images;
- validation that you actually ran.

## Steps

1. **Gather.** Read the commits and the full diff between **base** and
   **head**. Describe what the code does. When you are describing an existing
   PR, its current description and conversation stay closed unless the user
   opens them. Done when every changed file falls under a Changes bullet or a
   Risk note.
2. **Title.** Write the title as `<type>(<scope>): <description>`.
   - **type:** the dominant change, such as `fix` for a closed gap or `feat`
     for a new capability.
   - **scope:** the module that most of the diff touches.
   - **description:** imperative, lower case.

   Done when the title fits on one line and names the user-visible effect.
3. **Before and After.** When the diff changes the frontend, or adds a feature
   that appears in the UI, capture each changed screen at base and at head by
   following [`references/before-after.md`](references/before-after.md).
   Otherwise, write the reason there are no images. Done when each changed
   screen has an inspected image pair, or the section explains why there are
   none.
4. **Validate.** Find the repository's check commands in its scripts and CI.
   On head, run:
   - format, lint, and typecheck for the touched packages;
   - the tests that cover the changed files;
   - the browser test for each changed screen.

   Done when every Validation row is a command you ran, with its real result,
   and every check you skipped is named.
5. **Write.** Draft the title and body, matching
   [`references/example.md`](references/example.md). Done when every
   [section](#sections) is filled.
6. **Publish.** Open or update the PR only when the user or the calling skill
   asks. If a PR already exists for the branch, update its title and body.
   Upload the images to the PR. When PR-linking tools are available, link the
   PR to the thread. Done when the PR shows the drafted title and body and
   every image renders.
7. **Report.** Give the PR URL, or the full title and body when you did not
   publish, then the validation results and any skipped checks.

## Sections

| Section              | Contains                                                                                     |
| -------------------- | -------------------------------------------------------------------------------------------- |
| **Summary**          | The behaviour after this PR, in two to four sentences.                                       |
| **Why**              | What was wrong or missing before, as something a user or record would show.                  |
| **Changes**          | A summary grouped by app or package: one bullet per behaviour change, naming the function, field, or component that carries it. Tests, types, helpers, and call sites fold into the bullet they serve. |
| **Before and After** | An image table per changed screen, each with one line on what differs. With no images: `No image attached.` followed by the reason. |
| **Validation**       | A table of check, command, and result. Then the temporary steps, and what wasn't run.          |
| **Risk**             | Contract changes, behaviour that existing clients will notice, and coverage that was lost.    |
| Issue reference      | `Closes #N` when this PR completes the issue; `Refs #N` for partial or uncertain work.        |
| Attribution          | A line the harness asks you to end PR descriptions with, such as `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. It goes directly above the Model line. Leave it out when the harness doesn't ask for one. |
| Model                | The last line: `Model: <display name>`, the display name of the model you run as (such as `Claude Opus 5.5`), not its model ID. When other models wrote the branch's code, such as delegated workers, list every display name, comma-separated. |
