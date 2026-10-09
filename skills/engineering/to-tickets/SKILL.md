---
name: to-tickets
description: "Break a spec, or a small issue such as a reported bug, into small tickets that each pass interrogation as one PR."
disable-model-invocation: true
---

# To Tickets

Break a spec into **small** tickets. Each ticket is one PR, built in one
session, and must pass [interrogation](../interrogation/SKILL.md) under one
**intent**.

A small issue with no spec, such as a reported bug, becomes a **direct
ticket**: one build ticket written straight from the issue. The issue
qualifies when:

- it fits the [ticket rules](#ticket-rules) as a single build ticket;
- the issue and the source-of-truth docs answer every question the fix
  raises, so no decision is open.

## Steps

1. **Route.** A spec takes every step below. An issue with no spec is a
   direct ticket if it meets the bar above; otherwise recommend running
   `specs` on it first, and stop. Done when you have named the route.
2. **Gather.** Treat these as your only evidence:
   - the spec: its stories, rules, scope, and decisions. A direct ticket uses
     the issue instead: its body, comments, and reproduction steps;
   - the source-of-truth docs on module boundaries, naming, API shape, and
     testing.

   Existing tickets and code stay closed unless the user opens them. Read the
   interrogation bar in [`rubric.md`](../interrogation/references/rubric.md)
   and [`code-quality-review.md`](../interrogation/references/code-quality-review.md).
   Done when you know which module owns each record the work touches.
3. **Decide.** Turn the spec's decisions into decision tickets. Group the
   decisions that block the same build ticket. Done when every decision sits
   in a ticket that names what it blocks. A direct ticket skips this step; if
   you find an open decision, it no longer qualifies, so recommend `specs`.
4. **Slice.** Cut the build work into tickets along these seams, in order:
   - **Owner.** A module's command is its own ticket, and its caller is
     another.
   - **Layer.** The API ticket comes first, then the UI ticket that uses it.
   - **Case.** Each branch of a matrix (state, lock, posted or not) is its own
     handler ticket.

   Done when every ticket meets the [ticket rules](#ticket-rules). A direct
   ticket stays one ticket; if it needs a second, recommend `specs`.
5. **Write.** Write `<issue-number>-tickets.md` in the working directory,
   matching [`references/example.md`](references/example.md). The sections
   are:
   - Ticket rules;
   - Order, a dependency sketch;
   - decision tickets;
   - build tickets;
   - Coverage check.

   A direct ticket's file holds only the Ticket rules and its one build
   ticket, whose header line names the issue in place of stories. Acceptance
   includes a test that fails on the reported behaviour before the fix.

   Done when every ticket has a header line, an Intent, Acceptance criteria,
   and a Not in this PR list.
6. **Check.** Verify the file:
   - every story and decision appears in the Coverage check. For a direct
     ticket, its Acceptance covers everything the issue reports;
   - every Blocked by and every Not in this PR names a real ticket;
   - the graph has no cycles.

   Then read each ticket as an interrogation reviewer. Anything you would flag
   is either an acceptance criterion or listed in Not in this PR. Done when
   every ticket passes that read.
7. **Report.** Give the file path, the route, the ticket count, and the
   tickets that can start today. Publish to GitHub only when the user asks.

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
