---
name: pr
description: "Pull request writing. Use when preparing or opening a pull request for a branch, including a release PR that promotes an integration branch to a release branch."
---

# PR

Write a pull request description that a reviewer can trust without asking the
author anything. Every claim rests on **proof**:
- the diff;
- before and after images;
- validation that you actually ran.

## Release PRs

A PR is a **release PR** when all three hold:
- the head is an integration branch, such as `dev`;
- the base is a release or main branch, such as `version-4` or `main`;
- the range holds only merges of PRs that were already reviewed.

For a release PR, follow [`references/release.md`](references/release.md)
instead of steps 1 to 5 and the [sections](#sections) below. Then continue
from step 6, and report the merge check in place of validation results.

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
   PR to the thread by its URL, so T3 resolves the host. Done when the PR shows
   the drafted title and body and every image renders.
7. **Guide.** Only when the user, the calling skill, or the repository
   instructions ask for a review guide. After the push, call
   `write_pull_request_guides` with the PR's URL. It returns at once and a
   guide takes minutes, so don't wait. Record the outcome: `started`,
   `running`, or `failed` and why. "Review guides are off" or a repository
   with no checkout here is a skipped step, not a blocker. When updating a
   PR, call `read_pull_request_guide` first, and rewrite only a guide that
   exists and is `stale`. Done when the guide's outcome is recorded, or the
   step is skipped because nobody asked.
8. **Report.** Give the PR URL, or the full title and body when you did not
   publish, then the validation results, any skipped checks, and the review
   guide's outcome when one was asked for.

## Sections

| Section              | Contains                                                                                     |
| -------------------- | -------------------------------------------------------------------------------------------- |
| **Summary**          | The behaviour after this PR, in two to four sentences.                                       |
| **Why**              | What was wrong or missing before, as something a user or record would show.                  |
| **Changes**          | A summary grouped by app or package: one bullet per behaviour change, naming the function, field, or component that carries it. Tests, types, helpers, and call sites fold into the bullet they serve. |
| **Before and After** | An image table per changed screen, each with one line on what differs. With no images: `No image attached.` followed by the reason. |
| **Validation**       | A table of check, command, and result. Then the temporary steps, and what wasn't run.          |
| **Risk**             | Contract changes, behaviour that existing clients will notice, and coverage that was lost.    |
| Issue reference      | The closing reference `docs/agents/issue-tracker.md` documents, such as `Closes #N`, when this PR completes the issue; `Refs #N` for partial or uncertain work. |
| Attribution          | A line the harness asks you to end PR descriptions with, such as `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. It goes directly above the Model line. Leave it out when the harness doesn't ask for one. |
| Model                | The last line: `Model: <display name>`, the display name of the model you run as (such as `Claude Opus 5.5`), not its model ID. When other models wrote the branch's code, such as delegated workers, list every display name, comma-separated. |
