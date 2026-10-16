---
name: specs
description: "Use for \"spec\", \"write a spec\", \"spec this issue\", \"turn this issue into a spec\", or \"one-page spec\". Builds a lean spec from the source-of-truth docs and turns every gap into a decision."
disable-model-invocation: true
---

# Specs

Write a **lean** spec: one page a human reads in five minutes. It must be built
only from the **source of truth**, and every **gap** goes to the human as a
decision.

## Where the spec lives

The spec lives in the thread, where the user reads and answers it:

- Show the whole spec in your reply. A file path or a summary is not enough.
- Don't write it to a file unless the user asks for one. Publishing doesn't
  need a local copy.
- After every revision, such as an answered decision, show the whole spec
  again. The newest spec in the thread is the current one, and anything you
  publish matches it.

## Steps

1. **Gather.** Read these, and treat them as your only evidence:
   - the issue's body and comments;
   - the repository's source-of-truth docs it names;
   - the docs that cover its domain: glossary, requirements, workflows, data
     model, controls.

   Existing specs and code stay closed unless the user opens them. Done when
   every reference the issue names has been read.
2. **Draft.** Fill the [sections](#sections) in order, as the markdown your
   reply will show. Match the depth and tone of
   [`references/example.md`](references/example.md). Done when every section
   has content.
3. **Trace.** Check each rule, scope line, and actor against a source.
   - A rule with no source is a gap.
   - Two sources that disagree are a gap.
   - A term the issue uses differently from `GLOSSARY.md` is a gap.

   Move every gap to Decisions. Done when each remaining rule has a source and
   each gap has a Decisions row.
4. **Prune.** Cut to about 700 words:
   - Delete any sentence a reader could drop without losing a rule, scope
     line, or decision.
   - Merge user stories that describe the same capability.
   - Keep table and column names, code paths, and API shapes for
     implementation.

   Done when the spec fits one page and every section is still present.
5. **Report.** Reply with the number of decisions and the top
   recommendation, then the whole spec. Publish to an issue, PR, or doc only
   when the user asks. Done when the whole spec is in the thread.

## Sections

Every spec has these sections, in this order. Add other sections only when the
user asks for them.

| Section                          | Contains                                                                                     |
| -------------------------------- | -------------------------------------------------------------------------------------------- |
| **Problem**                      | What is broken or missing today, as something a user can observe.                            |
| **Why**                          | What that costs people, the business, or compliance.                                         |
| **Scope**                        | Bulleted capabilities this work delivers.                                                    |
| **Out of scope**                 | Nearby work by name, with where it goes instead (later milestone, existing flow).            |
| **Actors**                       | Table: who and what they do. Include separation-of-duty rules here.                          |
| **User stories**                 | Numbered, one per capability: "As a ‹actor›, I ‹action›, and ‹outcome›."                     |
| **Rules that matter**            | Bullets grouped by capability. Each is plain-language behaviour a reviewer could test.       |
| **What success looks like**      | Observable outcomes that prove the problem is gone.                                          |
| **Decisions needed before building** | Table: decision, resolve-by tag, recommendation.                                         |

## Decisions

Each gap becomes one row phrased as a question the human can answer. Tag how it
gets resolved:

- **Research**: needs outside authority, such as law, regulation, or vendor
  docs. The recommendation reads "none until authority is found".
- **Triage**: an owner's call, or a fix to make two docs agree. Recommend the
  safer option.
- **Grilling**: fog the docs can't clear, such as a design trade-off, to
  stress-test with the user through the `grilling` skill. Recommend one
  option and give a short reason.
