---
name: swarm-tickets
description: "Claim a batch of tickets and implement them in parallel, one T3 Code subagent per ticket."
disable-model-invocation: true
metadata:
  opencode/autoinvoke: "false"
---

# Swarm Tickets

You are the **parent**. You pick a batch of tickets, claim them, and hand each claimed ticket to its own T3 Code **worker**, which implements it with the `implement` skill. One claimed ticket gets one worker. You own everything outside a single ticket: ticket selection, file ownership, ordering, acceptance, integration, commits, PRs, and tracker updates.

Workers can run on any harness, model, and effort that T3 offers, so they don't have to match the parent. For example, a Claude Opus 5.5 · High parent can run Opus 5.5 · Medium workers or Codex GPT-6.1-Sol · High workers.

This skill owns the ticket workflow. All T3 Code orchestration (tool names, target resolution, dispatch, status, further rounds, cancelling) lives in `delegate-subagents`, which this skill invokes in preflight and defers to at every phase that points to it.

The workflow has six phases, run in order: **preflight → claim → plan waves → dispatch → accept → deliver**. Each phase ends on a "Done when" line. Finish that phase before starting the next.

## Harness notes

This skill runs on both Claude Code and Codex, and workers may run on either one.

| | Claude Code | Codex |
| --- | --- | --- |
| Invoke this skill (user only) | `/swarm-tickets` | `$swarm-tickets` |
| Invoke `delegate-subagents` and `pr` / load `implement` | Skill tool; the "Base directory" line gives the absolute path | Available-skills catalog entry |
| Track the ledger | The todo/task tool, or the conversation | `update_plan`, or the conversation |

Workers can't count on either harness's skill syntax, so the worker brief points at `implement` by absolute file path.

## The ledger

Keep one **ledger** for the batch, either in your context or in the plan tool. It is the source of truth for every phase. Record:

- **Batch:** a unique batch ID, the ticket source, the absolute checkout path, and the worker selection line (provider · model · options · runtime mode).
- **Per ticket:** source and ID, claim outcome (claimed / local claim / selected-but-unclaimed / skipped and why), acceptance criteria, dependencies, owned files, wave, execution state, current `clientRequestId`, `taskId` (keep earlier ones too), a selection override if the user gave this ticket its own target, and validation evidence.

A worker is **settled** when its task is terminal and `hasPendingChildRuns` is false. "Settled" means the worker has stopped. It does not mean the work was accepted.

## 1. Preflight

1. **Orchestration.** Invoke `delegate-subagents` as the harness table shows. If your catalog doesn't have it, read this repo's copy at [`../delegate-subagents/SKILL.md`](../delegate-subagents/SKILL.md). Use its phases 2–4 for every worker; the brief in phase 4 here replaces its phase 1. If it is unavailable, stop and report it.
2. **Ticket source.** Get it from the user's request or the repository instructions. Read the tickets, their acceptance criteria and dependencies, and any project guidance that applies. If you can't find the source, ask the user where it is before you claim anything.
3. **Count.** Use the ticket IDs and count the user asked for. An explicit list sets the count when the user gives none. For a backlog with no count, ask how many to claim. The count must be a positive integer. If the list and the count conflict, ask the user to resolve it.
4. **Implement skill.** Load `implement` as the harness table shows. If your catalog doesn't have it, use this repo's copy at [`../../engineering/implement/SKILL.md`](../../engineering/implement/SKILL.md). Record its absolute path for the worker briefs. If it is missing, stop and report it.
5. **PR skill.** Confirm `pr` resolves as the harness table shows, or at this repo's copy at [`../../engineering/pr/SKILL.md`](../../engineering/pr/SKILL.md). You invoke it in phase 6, so don't load it yet. If it is missing, tell the user before you claim anything.
6. **Worker target.** Turn the user's wording ("Claude Opus 5.5 Medium with Full Access", "Codex GPT 6.1 High") into a selection by following phase 2 of `delegate-subagents`. All workers use that selection unless the user gives specific tickets their own target. Tell the user the selection line.

Done when: `delegate-subagents` is loaded, `pr` resolves, and the source, count, `implement` path, and worker selection are all resolved, or a blocker has been reported to the user.

## 2. Claim

A ticket is **eligible** when all of these hold:

- it is unclaimed
- it is within the user's scope
- each prerequisite is either already satisfied or is another ticket in the selected batch, and the batch's dependency graph has no cycles

A prerequisite outside the batch, or a dependency cycle, makes a ticket ineligible.

Claim each eligible ticket exactly once. Re-check its current owner and prerequisites at the moment you claim it, and leave tickets that someone else has claimed alone. Use the source's own claim convention, within what the user has authorized. Assigning tickets, changing their status, and commenting on the tracker each need that authorization. If the source has no claim operation, record ownership in the ledger as a **local claim** and say so in the final report.

Claim tickets that depend on other batch tickets now, and hold their dispatch until phase 5. If the source's rules forbid reserving blocked tickets, record those tickets as **selected-but-unclaimed** and claim them once the rules allow it.

A ticket counts as claimed only after the source claim succeeds or the local claim is recorded. A failed claim gets no worker. You may select replacement tickets only when the user asked for a count from a backlog, and only from that source and within that count. If fewer tickets are eligible than requested, continue with the smaller batch and report the shortfall. The batch is fixed once this phase ends. Finish it before pulling any new tickets.

Done when: every selected ticket has a claim outcome in the ledger.

## 3. Plan waves

Every worker runs in the parent's checkout (phase 3 of `delegate-subagents`), so concurrent workers share one working tree and file ownership is what keeps them apart.

Assign each ticket the files it owns, including its tests, generated files, and any shared configuration it touches. Changes the user already has in the checkout stay outside every worker's ownership.

Then group the tickets into **waves**. A wave is a set of tickets with disjoint file ownership and no dependencies on each other, so it can run concurrently. A ticket that shares files with another ticket, or needs another ticket's result, goes in a later wave than that ticket.

Done when: every claimed ticket has its owned files and a wave in the ledger.

## 4. Dispatch

Dispatch each ticket in the current wave as a T3-owned child, following phase 3 of `delegate-subagents`, even when the worker runs on your own provider. Use these ticket-specific values:

- `task`: the brief below, with every field filled in
- `title`: `<ticket ID>: <ticket title>`
- `role`: `implementation`
- selection: the ticket's override, or the batch selection
- `clientRequestId`: `<batchId>-<ticketId>-a<attempt>`

Write the returned `taskId` to the ledger immediately.

Workers see only the brief you send. Fill it in with facts you have already resolved:

```text
Read the skill at <absolute path to implement/SKILL.md> and follow it for this ticket.

Ticket: Source, ID, title, complete requirements, and acceptance criteria.
Workspace: Absolute checkout path and current branch.
Project guidance: Applicable instructions and accessible document paths.
User constraints: Requested behavior, exclusions, and delivery instructions.
Ownership: Files you may change, tests you own, and other workers' boundaries.
Dependencies: Completed prerequisites, the interfaces they actually produced, and relevant findings.
Validation: Ticket-specific checks and repository commands.

Scope: Implement this ticket and validate the affected behavior. Stay inside
your owned files. If you need a file outside them, stop and report which file
and why. The parent handles git commits, branch changes, pushes, PR creation,
and tracker updates; this overrides the commit/push/PR step in implement. Do
the work yourself rather than delegating it to further workers.

Return: Acceptance criteria satisfied, changed files, exact checks run and
their results, remaining failures or blockers, and any shared changes the
parent needs to make.
```

Done when: every ticket in the current wave has a `taskId` in the ledger.

## 5. Accept

**Waiting.** When only worker work remains, report the ticket → `taskId` mapping and end your turn. Read results with phase 4 of `delegate-subagents`. A completion notification is one checkpoint. It doesn't mean the batch is done.

**Accepting a ticket.** First confirm the worker is settled. A finished worker turn doesn't prove the ticket is implemented. Check every acceptance criterion against the actual changed files and the validation evidence. Then record the ticket as accepted or needing correction.

**Advancing waves.** Start the next wave only after every ticket it depends on is settled and accepted. At that point, release the earlier tickets' file ownership and fill in the new briefs' Dependencies field with the interfaces and findings those tickets actually produced. Each ticket has at most one active worker at a time.

**Correcting or retrying.** First inspect the worker's partial changes and bring the ledger up to date. Then start another round as `delegate-subagents` describes, as attempt `-a2`, … with the same selection, adding the current artifacts and the criteria still unmet. Record the new `taskId` against the same ticket and keep the old one.

**Cancelling.** Cancel through `delegate-subagents` when the user stops a worker, or when a worker that is still running has to be replaced. Before you replace the worker or release its files, confirm it has stopped and inspect its partial changes. Keep the evidence. When a ticket fails the same way twice, mark it blocked and report it instead of retrying again.

Done when: every claimed ticket is settled and recorded as accepted, blocked, or cancelled.

## 6. Deliver

Review the combined changes against every ticket's acceptance criteria and do any integration work that spans tickets. Then, once for the whole batch:

1. **Validate.** Run the repository's typecheck and full test suite on the combined changes.
2. **Commit and push.** Use the branch and PR structure the user asked for. Stage only changes the batch owns.
3. **Open the PRs.** For each PR the batch opens or updates, invoke `pr` as the harness table shows. If your catalog doesn't have it, read this repo's copy at [`../../engineering/pr/SKILL.md`](../../engineering/pr/SKILL.md). Ask it to publish, and give it the base, the head, the batch's tickets, and the worker models. The description it drafts is the PR body. Never open or update a PR with a description you wrote by hand, such as through a bare `gh pr create` or `glab mr create`.

Report checks you couldn't run, and failures that existed before the batch, as they are.

If PR linking tools are available, call `link_pull_request` for every PR you created or worked on, then confirm the full set with `list_thread_pull_requests`. Close tickets in the tracker only when the source's rules and the user's authorization allow it. A worker finishing is not enough to close a ticket.

**Handoff before delivery.** If the user wants to stop before commits or PRs, mark validated tickets in the ledger as awaiting delivery and keep their artifacts and validation evidence. Record blocked and cancelled claims explicitly. Release local file ownership only for settled workers. Release external claims according to the source's convention and the user's existing authorization.

**Final report.** Give the worker selection line. For each ticket, give its state (completed, failed, blocked, cancelled, or still running), its validation evidence, delivery links, and any unresolved blockers. Include any claim shortfall and any local claims. For unfinished work, include the ticket → `taskId` mapping.

## Example

```text
/swarm-tickets
claim 3 tickets
<ticket link 1>
<ticket link 2>
<ticket link 3>
and delegate the implementation to Claude Opus 5.5 Medium with Full Access
```

The parent resolves the last line to `claudeAgent · claude-opus-5-5 · effort=medium · full-access` and dispatches three workers with that selection. Ending with "to Codex GPT 6.1 High with Full Access" instead resolves to `codex · gpt-6.1-sol · reasoningEffort=high · full-access`. In Codex, start the request with `Use $swarm-tickets to …`.
