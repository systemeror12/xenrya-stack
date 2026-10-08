---
name: to-tickets
description: "Ticket writing. Use when breaking a spec into tickets."
---

# To Tickets

Break a spec into **small** tickets. Each ticket is one PR, built in one
session, and must pass [interrogation](../interrogation/SKILL.md) under one
**intent**.

## Steps

1. **Gather.** Treat these as your only evidence:
   - the spec: its stories, rules, scope, and decisions;
   - the source-of-truth docs on module boundaries, naming, API shape, and
     testing.

   Existing tickets and code stay closed unless the user opens them. Read the
   interrogation bar in [`rubric.md`](../interrogation/references/rubric.md)
   and [`code-quality-review.md`](../interrogation/references/code-quality-review.md).
   Done when you know which module owns each record the spec touches.
2. **Decide.** Turn the spec's decisions into decision tickets. Group the
   decisions that block the same build ticket. Done when every decision sits
   in a ticket that names what it blocks.
3. **Slice.** Cut the build work into tickets along these seams, in order:
   - **Owner.** A module's command is its own ticket, and its caller is
     another.
   - **Layer.** The API ticket comes first, then the UI ticket that uses it.
   - **Case.** Each branch of a matrix (state, lock, posted or not) is its own
     handler ticket.

   Done when every ticket meets the [ticket rules](#ticket-rules).
4. **Write.** Write `<issue-number>-tickets.md` in the working directory,
   matching [`references/example.md`](references/example.md). The sections
   are:
   - Ticket rules;
   - Order, a dependency sketch;
   - decision tickets;
   - build tickets;
   - Coverage check.

   Done when every ticket has a header line, an Intent, Acceptance criteria,
   and a Not in this PR list.
5. **Check.** Verify the file:
   - every story and decision appears in the Coverage check;
   - every Blocked by and every Not in this PR names a real ticket;
   - the graph has no cycles.

   Then read each ticket as an interrogation reviewer. Anything you would flag
   is either an acceptance criterion or listed in Not in this PR. Done when
   every ticket passes that read.
6. **Report.** Give the file path, the ticket count, and the tickets that can
   start today. Publish to GitHub only when the user asks.

## Ticket rules

Copy these into the tickets file. Every build ticket follows them.

- **One intent.** The Intent paragraph doubles as the PR description, and
  reviewers judge the code against it.
- **Small.** One module, or one call across a module boundary. Roughly 400
  lines of production code.
- **Files stay under 1,000 lines.** Give each new command its own service file
  and each new rule its own domain service. When an existing file would cross
  1,000 lines, its split is a ticket of its own that comes first.
- **Only what's used now.** Build what this ticket's behaviour needs. Later
  cases arrive as their own tickets.
- **Canonical home.** Controllers carry transport only. A module changes
  another module's records through that module's application service. Each
  case gets its own handler beside the others.
- **Later work is named.** Not in this PR points to the ticket that covers it,
  so the lead reviewer can dismiss "missing" findings.
- **Proven at the boundary.** Acceptance names the tests that matter:
  - atomic rollback, retry, race, and cross-tenant access on the real
    database;
  - a browser test for each UI ticket.

## Ticket shapes

- **Decision:** a resolve-by tag (Research, Triage, or Grilling), the options,
  one recommendation, and a Done when list. Done when means the answer is
  recorded and the docs agree with it.
- **Build:** a header line with the module, Blocked by, and the stories it
  covers. Then Intent (one paragraph), Acceptance (checkboxes a reviewer can
  test), and Not in this PR.
