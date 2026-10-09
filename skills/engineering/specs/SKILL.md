---
name: specs
description: "Turn an issue into a lean one-page spec from the source-of-truth docs."
disable-model-invocation: true
---

# Specs

Write a **lean** spec: one page a human reads in five minutes. It must be built
only from the **source of truth**, and every **gap** goes to the human as a
decision.

## Steps

1. **Gather.** Read these, and treat them as your only evidence:
   - the issue's body and comments;
   - the repository's source-of-truth docs it names;
   - the docs that cover its domain: glossary, requirements, workflows, data
     model, controls.

   Existing specs and code stay closed unless the user opens them. Done when
   every reference the issue names has been read.
2. **Draft.** Fill the [sections](#sections) in order, in
   `<issue-number>-<slug>.md` in the working directory. Match the depth and
   tone of [`references/example.md`](references/example.md). Done when every
   section has content.
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
5. **Report.** Give the file path, the number of decisions, and the top
   recommendation. Publish to an issue, PR, or doc only when the user asks.

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
