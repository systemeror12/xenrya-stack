---
name: swarm-tickets
description: "Use for \"swarm\", \"swarm tickets\", \"swarm these tickets\", \"work tickets in parallel\", or \"claim N tickets\". Claims a batch of tickets and implements each in its own T3 Code worker thread."
disable-model-invocation: true
metadata:
  opencode/autoinvoke: "false"
---

# Swarm Tickets

You are the **parent**. You pick a batch of tickets, claim them, and hand each claimed ticket to its own T3 Code **worker**, a thread bound to the ticket's workspace that implements it with the `implement` skill. One claimed ticket gets one worker. You own everything outside a single ticket: ticket selection, workspaces, file ownership, ordering, acceptance, integration, commits, PRs, and tracker updates.

Workers can run on any harness, model, and effort that T3 offers, so they don't have to match the parent. For example, a Claude Opus 5.5 · High parent can run Opus 5.5 · Medium workers or Codex GPT-6.1-Sol · High workers.

This skill owns the ticket workflow. All T3 Code orchestration (tool names, target resolution, launching, waiting, reading, further rounds, cancelling) lives in `delegate-subagents` and its [Launched workers](../delegate-subagents/references/launched-workers.md) reference, which this skill invokes in preflight and defers to at every phase that points to it.

The workflow has seven phases, run in order: **preflight → claim → plan waves → dispatch → accept → deliver → revise**. Each phase ends on a "Done when" line. Finish that phase before starting the next. Phase 7 runs only when review findings or a base-branch update come back after delivery. [`references/example.md`](references/example.md) walks through a full batch.

## Hard rules

These rules hold in every phase. Breaking one breaks the workflow.

1. **Every worker is a launched thread.** Create each worker with `t3_thread_launch`, bound to its ticket's workspace, and follow it as [Launched workers](../delegate-subagents/references/launched-workers.md) describes. Every round, the brief included, goes to that thread through a background CLI send. Never create a worker with `delegate_task` or `create_threads`: a `delegate_task` child either shares this thread's checkout or gets a worktree of this thread's commit on a branch T3 names, so it can't be bound to the ticket's base and branch. Invoking this skill is the user's request for one top-level thread per ticket.
2. **Wait by ending the turn.** Each worker's background send wakes you when its round ends, so after dispatching, report the ticket → thread table and end the turn. Don't run `sleep` or poll. To wait on another shell process, such as a validation run or a worker's leftover processes, use the harness's background waiting tool from the [harness table](#harness-notes).
3. **Every PR goes through `pr`.** Each time you open or update a PR, including after a correction round or a base-branch merge, invoke the `pr` skill for that PR and publish the body it drafts. Never write a PR body yourself, and never run `gh pr create`, `gh pr edit --body`, `glab mr create`, or similar with text you wrote.
4. **Accepting the last ticket starts delivery.** When the last ticket in the batch is accepted, go straight on to phase 6 in that turn. Stop before delivery only if the user asked you to.

## Turn map

Each turn starts on a trigger and ends in one way only:

| Trigger | What you do | End the turn with |
| --- | --- | --- |
| The user's request | Phases 1–4 for the first wave | The selection line and the ticket → thread table |
| A worker's send exits | Phase 5 for that worker: accept it or send a correction, and dispatch any wave it unblocks. Accepting the last ticket starts phase 6 | The workers still running, or the final report with the PR links |
| A turn with no send exit to explain it: the user interrupted, or T3 sent "Continue where you left off." after a restart | Check every running worker as Launched workers' Send a round describes, answer the user, then go on with phase 5 | As for a send exit |
| Review findings, a base-branch update, or a PR watch waking you | Phase 7 | The updated final report |

When the ledger is no longer in your context, because this thread was compacted, rebuild it first: from the last ledger table you reported, or from `t3_thread_list` with `titleContains: "<batchId>"`.

## Harness notes

This skill runs on both Claude Code and Codex, and workers may run on either one.

| | Claude Code | Codex |
| --- | --- | --- |
| Invoke this skill (user only) | `/swarm-tickets` | `$swarm-tickets` |
| Invoke `delegate-subagents` and `pr` / load `implement` | Skill tool; the "Base directory" line gives the absolute path | Available-skills catalog entry |
| Track the ledger | The todo/task tool, or the conversation | `update_plan`, or the conversation |
| Wait on a shell process | Bash with `run_in_background: true` running an `until` loop, or the Monitor tool | A background terminal session |

Workers can't count on either harness's skill syntax, so the worker brief points at `implement` by absolute file path.

## The ledger

Keep one **ledger** for the batch, either in your context or in the plan tool. It is the source of truth for every phase. Record:

- **Batch:** a unique batch ID, the ticket source, the base branch and commit, the workspace mode, the worker selection line (provider · model · options · runtime mode), and the base branch's known failures.
- **Per ticket:** source and ID, claim outcome (claimed / local claim / selected-but-unclaimed / skipped and why), acceptance criteria, dependencies, workspace path and branch, owned files, reserved sequence numbers, wave, execution state, worker `threadId` and run tag (keep earlier ones too), read position, the current round number, a selection override if the user gave this ticket its own target, validation evidence, and PR URL.

A worker is **settled** when its newest run is terminal and `t3_queue_list` shows nothing queued on its thread, as [Launched workers](../delegate-subagents/references/launched-workers.md) describes. "Settled" means the worker has stopped. It does not mean the work was accepted.

## 1. Preflight

1. **Orchestration.** Invoke `delegate-subagents` as the harness table shows. If your catalog doesn't have it, read this repo's copy at [`../delegate-subagents/SKILL.md`](../delegate-subagents/SKILL.md). Use its phase 2 for the worker selection and its Launched workers reference for every worker; the brief in phase 4 here replaces its phase 1. If it is unavailable, stop and report it. In Claude Code, load the T3 schemas you'll need in one ToolSearch call: `select:mcp__t3-code__orchestrator_capabilities,mcp__t3-code__t3_thread_launch,mcp__t3-code__t3_thread_list,mcp__t3-code__t3_thread_wait,mcp__t3-code__t3_thread_read,mcp__t3-code__t3_thread_interrupt,mcp__t3-code__t3_pending_request_list,mcp__t3-code__t3_pending_request_read,mcp__t3-code__t3_pending_request_respond,mcp__t3-code__t3_queue_list,mcp__t3-code__t3_queue_cancel,mcp__t3-code__t3_workflow_stop,mcp__t3-code__t3_thread_search,mcp__t3-code__link_pull_request,mcp__t3-code__list_thread_pull_requests,mcp__t3-code__watch_pull_request,mcp__t3-code__unwatch_pull_request`.
2. **Ticket source.** Get it from the user's request or the repository instructions. Read the tickets, their acceptance criteria and dependencies, and any project guidance that applies, including `AGENTS.md` or `CLAUDE.md` and any worktree setup script it names. If you can't find the source, ask the user where it is before you claim anything.
3. **Count.** Use the ticket IDs and count the user asked for. An explicit list sets the count when the user gives none. For a backlog with no count, ask how many to claim. The count must be a positive integer. If the list and the count conflict, ask the user to resolve it.
4. **Implement skill.** Load `implement` as the harness table shows. If your catalog doesn't have it, use this repo's copy at [`../../engineering/implement/SKILL.md`](../../engineering/implement/SKILL.md). Record its absolute path for the worker briefs. If it is missing, stop and report it.
5. **PR skill.** Confirm `pr` resolves as the harness table shows, or at this repo's copy at [`../../engineering/pr/SKILL.md`](../../engineering/pr/SKILL.md). You invoke it in phase 6, so don't load it yet. If it is missing, tell the user before you claim anything.
6. **Worker target.** Turn the user's wording ("Claude Opus 5.5 Medium with Full Access", "Codex GPT 6.1 High") into a selection by following phase 2 of `delegate-subagents`. All workers use that selection unless the user gives specific tickets their own target. A launched worker can't run with broader runtime or interaction modes than this thread, so compare the selection with the `runtimeMode` and `interactionMode` that `orchestrator_capabilities` reports, and with the provider's `runtimeModes`, and stop and tell the user if it asks for more. Don't select Claude's `ultracode` effort unless the user names it: it runs multi-agent workflows, which the worker brief forbids. Tell the user the selection line and that each worker will be its own top-level thread.
7. **Baseline.** Fetch the base branch and record its commit. Run the repository's cheap checks (format, lint, typecheck) on it once, and record each failure that already exists there. Workers get this list so they don't chase failures they didn't cause.

Done when: `delegate-subagents` is loaded, `pr` resolves, and the source, count, `implement` path, worker selection, base commit, and baseline failures are all resolved, or a blocker has been reported to the user.

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

### Workspaces

Pick one workspace mode for the batch and record it in the ledger.

- **Shared checkout** (the default). Every worker is bound to the parent's checkout: `{"type": "root"}` when the parent runs in the project's main checkout, otherwise `existing_worktree` with the parent's worktree path and branch. Concurrent workers share one working tree, and file ownership is what keeps them apart.
- **Worktree per ticket.** Use it when the user asks for it ("each ticket has its own worktree", "one branch per ticket") or the repository guidance requires it. Each ticket gets its own branch and directory, and each becomes its own PR.

For a worktree per ticket, **you** create the worktrees and run their setup, and each worker is launched bound to its worktree with `existing_worktree`. Don't let `t3_thread_launch` create them with `"type": "worktree"`: T3's preparation doesn't run the setup script `AGENTS.md` names, and launching several at once would prepare them in parallel.

1. Use the repository's worktree convention if it has one, such as an existing worktree directory or branch prefix. Otherwise create them beside the checkout:
   ```bash
   git fetch origin <base>
   git worktree add -b <prefix>/issue-<N> <worktree root>/issue-<N> origin/<base>
   ```
2. Run the repository's worktree setup script (the one `AGENTS.md` names) in each worktree, **one worktree at a time**. Setup scripts often claim ports, databases, or package stores, and running them in parallel races. Record each worktree's ready line, database, and ports.
3. Record each worktree's absolute path and branch against its ticket.

Done when the workspace for every ticket in the wave exists and its setup has passed.

### Ownership and waves

Assign each ticket the files it owns, including its tests, generated files, and any shared configuration it touches. Changes the user already has in the checkout stay outside every worker's ownership. With a worktree per ticket, each ticket owns its whole worktree, but the tickets still collide when they merge into the same base.

**Reserve shared sequences.** If the tickets may each add a numbered artifact, such as a database migration, give each ticket its own number now, in the order the PRs are likely to merge. Put the reserved number in the brief. Two tickets that both take the next free number make you rename applied migrations later.

Then group the tickets into **waves**. A wave is a set of tickets with disjoint file ownership and no dependencies on each other, so it can run concurrently. A ticket that shares files with another ticket, or needs another ticket's result, goes in a later wave than that ticket. With a worktree per ticket, only dependencies decide the waves.

Done when: every claimed ticket has a workspace, owned files, any reserved numbers, and a wave in the ledger.

## 4. Dispatch

Launch each ticket in the current wave with `t3_thread_launch`, then send it the brief below, following [Launched workers](../delegate-subagents/references/launched-workers.md) in `delegate-subagents`, even when the worker runs on your own provider. Make the calls together when the harness supports parallel tool calls. Each call carries:

```json
{
  "title": "<ticket ID>: <ticket title> [<batchId>-<ticketId>-a<attempt>]",
  "modelSelection": {"instanceId": "<from the selection>", "model": "<from the selection>", "options": {"<option id>": "<value>"}},
  "runtimeMode": "<from the selection>",
  "workspaceStrategy": {"type": "existing_worktree", "worktreePath": "<the ticket's workspace>", "branch": "<its branch>"}
}
```

With a shared checkout, use the parent's strategy from [Workspaces](#workspaces). Use the ticket's override in place of the batch selection when it has one. Write each returned `threadId` and run tag to the ledger immediately. If a launch errors or its response is lost, look for its run tag with `t3_thread_list` before you launch again. Then start one background send per worker, carrying its brief with every field filled in.

Workers see only the brief you send. Fill it in with facts you have already resolved:

```text
Read the skill at <absolute path to implement/SKILL.md> and follow it for this ticket.

Ticket: Source, ID, title, complete requirements, and acceptance criteria.
Workspace: <absolute workspace path> on branch <branch>, from <base> (<commit>).
  This thread is bound to it: run every command there.
  [Worktree per ticket:] Setup already passed: <ready line, database, ports>.
Project guidance: Applicable instructions and accessible document paths.
User constraints: Requested behavior, exclusions, and delivery instructions.
Ownership: Files you may change, tests you own, and other workers' boundaries.
Reserved: Sequence numbers reserved for this ticket, such as its migration number.
Dependencies: Completed prerequisites, the interfaces they actually produced, and relevant findings.
Validation: Run typecheck, lint, and the tests that cover your changes. <Either:
  "Also run the full suite" (one worker, or shared checkout without a database
  suite) or: "Don't run the full or database suite; the parent runs it, one
  workspace at a time.">
  Failures already on <base>: <baseline list, or "none">. Don't fix them.

Scope: Implement this ticket and validate the affected behavior. Stay inside
your owned files. If you need a file outside them, stop and report which file
and why. The parent handles git commits, branch changes, pushes, PR creation,
and tracker updates; this overrides the commit/push/PR step in implement. Do
the work yourself rather than delegating it to further workers. Finish in
this one turn: if you're blocked, report the blocker in your Return rather than
asking a question. Don't leave background processes running when you finish.

Return: Acceptance criteria satisfied, changed files, exact checks run and
their results, remaining failures or blockers, and any shared changes the
parent needs to make.
```

Done when: every ticket in the current wave has a `threadId` in the ledger and a running send, and you have reported the selection line and the ticket → thread table.

## 5. Accept

**Waking.** Each send exit wakes you for one worker. Handle its exit code as Launched workers describes, read the result with `t3_thread_read`, and assess it with phase 4 of `delegate-subagents`. A returned worker is one checkpoint. It doesn't mean the batch is done.

**Accepting a ticket.** First confirm the worker is settled. A finished worker turn doesn't prove the ticket is implemented. Read the actual diff in the ticket's workspace and check every acceptance criterion against it and the validation evidence. Check that it used its reserved numbers. Then record the ticket as accepted or needing correction.

**Advancing waves.** Start the next wave only after every ticket it depends on is settled and accepted. At that point, release the earlier tickets' file ownership and fill in the new briefs' Dependencies field with the interfaces and findings those tickets actually produced. Each ticket has at most one active worker at a time.

**Correcting or retrying.** First inspect the worker's partial changes and bring the ledger up to date. Then send round 2, 3, … to the ticket's worker thread, as Launched workers' Another round describes, adding the current artifacts and the criteria still unmet. Record the round against the same ticket.

**Failed workers.** A worker can fail for reasons outside its work, such as a rate limit. Before you retry, check whether it left processes running in its workspace, such as a test run. If it did, wait for them with the background waiting tool, then inspect the workspace. If the launch itself failed, look for its run tag with `t3_thread_list` before you launch again. When the worker ran and then failed, send the next round to the same thread.

**Cancelling.** Stop a worker with `t3_thread_interrupt`, and any Claude workflow it runs with `t3_workflow_stop`, as Launched workers describes, when the user stops it, or when a worker that is still running has to be replaced. Before you replace the worker or release its files, confirm it has stopped and inspect its partial changes. Keep the evidence. When a ticket fails the same way twice, mark it blocked and report it instead of retrying again.

Done when: every claimed ticket is settled and recorded as accepted, blocked, or cancelled. Until then, end each turn with the workers still running. If this turn accepted the last ticket, continue to phase 6 now (hard rule 4).

## 6. Deliver

Work through this checklist in order, in the same turn. Tick each step in the ledger.

1. **Integrate.** Review the combined changes against every ticket's acceptance criteria and do any work that spans tickets. Fix collisions the waves couldn't prevent, such as duplicate migration numbers.
2. **Validate.** Run the repository's format, lint, typecheck, and full test suite on each PR's head. With a worktree per ticket, run the full and database suites **one worktree at a time**, because parallel runs fight over databases and tool caches. Start a long run with the background waiting tool, keep working on steps that don't depend on it, and continue when it reports. Compare every failure with the baseline from preflight.
3. **Commit and push.** Use the branch and PR structure the user asked for. With a worktree per ticket, commit in each worktree and push its branch. Stage only changes the batch owns. Follow the repository's commit style.
4. **Run `pr` for each PR.** For every PR the batch opens, invoke the `pr` skill once, as the harness table shows. If your catalog doesn't have it, read this repo's copy at [`../../engineering/pr/SKILL.md`](../../engineering/pr/SKILL.md) and follow it. Pass it:
   ```text
   Publish a PR. Base: <base>. Head: <branch>. Workspace: <absolute path>.
   Tickets: <ID and title>, Closes #<N>. Validation already run: <commands and results>.
   Code written by: <worker display names>. Orchestrated by: <your display name>.
   Review guide: <requested | not requested>.
   ```
   The title and body it drafts are what you publish. Hard rule 3 forbids anything else. Mark the review guide as requested only when the user or the repository guidance asks for one.
5. **Link.** If PR-linking tools are available, call `link_pull_request` with the PR's URL for every PR you created or updated, then confirm the full set with `list_thread_pull_requests` and link any that are missing. Also link each PR to its ticket's worker thread by passing that `threadId`, so the worker's thread shows the PR and settles when it merges.
6. **Tracker.** Close or update tickets only when the source's rules and the user's authorization allow it. A worker finishing is not enough to close a ticket. A closing reference such as `Closes #N` acts only when the PR merges into the default branch on hosts like GitHub and GitLab, so say so when the base is another branch. For other hosts, follow `docs/agents/issue-tracker.md`.
7. **Watch.** Only when the user asks you to watch the PRs: call `watch_pull_request` for each, send the final report, and end the turn. T3 wakes this thread on reviews, comments, failed checks, and base conflicts, which start phase 7. Call `unwatch_pull_request` for each PR when you hand the batch back.

Done when: every PR shows the body `pr` drafted, every PR is linked and, when the user asked, watched, and the final report below is sent.

**Handoff before delivery.** If the user wants to stop before commits or PRs, mark validated tickets in the ledger as awaiting delivery and keep their artifacts and validation evidence. Record blocked and cancelled claims explicitly. Release local file ownership only for settled workers. Release external claims according to the source's convention and the user's existing authorization.

**Final report.** Give the worker selection line. For each ticket, give its state (completed, failed, blocked, cancelled, or still running), its workspace and branch, its validation evidence, its PR link, and any unresolved blockers. Report checks you couldn't run, and failures that existed before the batch, as they are. When the PRs touch shared sequences or depend on each other, give the merge order. Include any claim shortfall and any local claims. End with the ledger table: ticket, worker thread (linked as `[title](t3-thread://v1/<threadId>)`), run tag, branch, PR, and last round. Phase 7 starts from it after this thread is compacted.

## 7. Revise

This phase runs when changes come back for PRs the batch delivered: findings from `interrogation` or a reviewer, or a PR that conflicts with its base. Keep the ledger from phases 1–6. You still own commits, pushes, and PRs.

**Review findings.**

1. Fix only what the lead judgment marked as fix-now, or, after a PR watch wake, the comments and failed checks the user accepts. A wake is news, not a verdict. Give the user the list before you dispatch, along with anything you are leaving out.
2. Route each PR's findings to its ticket. Unless the user names another target, send them to the ticket's worker thread as its next round, as Launched workers' Another round describes. That is what "send the findings back to the previous subagents" means. It does not mean the reviewers or the interrogation lead threads. If the ledger lost a worker's `threadId`, find the thread with `t3_thread_search` and the PR number. For another target, launch a new worker on the same worktree with a new run tag.
3. Write each correction message like this, then repeat the original brief's Validation, Scope, and Return fields:
   ```text
   This is round <n> (correction) for ticket <ID>. Round 1 is committed at
   <commit> on branch <branch> and open as <PR URL>. A review accepted these
   findings. Fix only these:
   - <finding: location, problem, the fix the lead judgment expects, the test that proves it>
   Do NOT change: <findings dismissed or deferred, and why>.
   ```
4. Report the revise table (PR, ticket, worker thread, round, fix) and end the turn. Each round's send exit brings you back to accept it as in phase 5.

**Base-branch updates.** When a PR conflicts with its base, update the branch in its workspace with the repository's convention. Look at the branch history to tell whether it merges the base or rebases onto it. Resolve the conflicts, apply any new migrations to the workspace's database, and validate as in phase 6.

**Redeliver.** For every PR that changed, run phase 6 steps 2–5 again: validate, commit, push to the same branch, invoke `pr` for that PR so it updates the title and body and refreshes a stale review guide, and link the PR again. A change too small for a new description still goes through `pr`.

Done when: every changed PR has passed validation, shows a body from `pr`, and is linked, and the updated final report is sent.

## Example

```text
/swarm-tickets
claim 3 tickets
<ticket link 1>
<ticket link 2>
<ticket link 3>
and delegate the implementation to Claude Opus 5.5 Medium with Full Access
```

The parent resolves the last line to `claudeAgent · claude-opus-5-5 · effort=medium · full-access` and launches three worker threads with that selection. Ending with "to Codex GPT 6.1 High with Full Access" instead resolves to `codex · gpt-6.1-sol · reasoningEffort=high · full-access`. Adding "each ticket has its own worktree from origin/dev" selects a worktree per ticket. In Codex, start the request with `Use $swarm-tickets to …`.

[`references/example.md`](references/example.md) follows one batch, with a worktree per ticket, from the request through review and a correction round.
