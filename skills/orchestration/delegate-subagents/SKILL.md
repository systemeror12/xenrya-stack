---
name: delegate-subagents
description: "Use for \"subagent\", \"delegate this\", \"hand this off\", \"run this on Codex\", \"run this on Claude\", \"use another model\", or \"at medium effort\". Runs scoped work on a chosen harness, model, and effort through T3 Code."
---

# Delegate Subagents

You are the **parent**. You turn the user's request into a bounded assignment, run it on the harness and model the user picked, and check the result. With T3 Code's `delegate_task`, a child can run on any enabled provider, so the parent and child may use different harnesses, models, and efforts:

```text
Parent: Claude Opus 5.5 · High  ──delegate_task──▶  Child: Claude Opus 5.5 · Medium · full-access
Parent: Claude Opus 5.5 · High  ──delegate_task──▶  Child: Codex GPT-6.1-Sol · High · full-access
```

You own integration and the final answer.

Two rules hold in every phase:

- **Children come from `delegate_task`, except launched workers.** Don't create a child with `t3_thread_launch` or `create_threads`. Those make top-level threads that never notify this one. Continue a child only as phase 4's [Another round](#4-assess-the-result) describes. The one exception is a **launched worker**: a worker that needs a workspace `delegate_task` can't give it, such as a worktree on a base and branch you choose, or one that a calling skill (`swarm-tickets`, `interrogation`) tells you to launch. Follow [`references/launched-workers.md`](references/launched-workers.md) for those.
- **Wait by ending your turn.** A child's completion wakes this thread with a notification, and a launched worker's round wakes it through the background CLI send that delivered it, as [Launched workers](references/launched-workers.md) describes. Don't run `sleep`, don't poll `task_status` in a loop, and don't call `t3_thread_wait` on a child's thread.

The workflow has four phases: **define → resolve target → dispatch → assess**. Other skills, such as `swarm-tickets`, write their own briefs and then follow phases 2–4 here for their workers.

## Harness notes

This skill runs on both Claude Code and Codex. The instructions use bare T3 tool names. Map them to your harness like this:

| | Claude Code | Codex |
| --- | --- | --- |
| T3 tool names | `mcp__t3-code__<tool>` | `mcp__t3_code__<tool>`; in code mode, `tools.mcp__t3_code__<tool>(args)` |
| T3 tools missing | Listed as deferred: load the schemas with ToolSearch, e.g. `select:mcp__t3-code__orchestrator_capabilities,mcp__t3-code__delegate_task,mcp__t3-code__task_status,mcp__t3-code__task_cancel,mcp__t3-code__t3_pending_request_read,mcp__t3-code__t3_pending_request_respond,mcp__t3-code__t3_queue_list,mcp__t3-code__t3_queue_cancel,mcp__t3-code__t3_thread_send` | Make one direct call to `orchestrator_capabilities` before you conclude T3 is unavailable |
| Native subagents | Agent tool | Codex native subagents |
| Wait on a shell process | Bash with `run_in_background: true` (up to `timeout: 7200000`) running the command or an `until` loop, or the Monitor tool | A background terminal session |
| T3 CLI | `t3` on PATH, or `~/.t3/bin/t3` | Same |

## 1. Define the assignment

Pick one concrete outcome for each delegate. Each assignment should be big enough to produce a useful result and should not overlap another writer's scope. Split work into multiple assignments only when the user asks for subagents or the active instructions authorize that delegation.

T3 children receive only the prompt you send, without the parent conversation, so the brief has to stand on its own:

```text
Task: The specific outcome to produce.
Workspace: The absolute checkout path and relevant files or artifacts.
Context: Required facts, excerpts, prior findings, and decisions.
Scope: Permitted changes, ownership boundaries, or a read-only assignment.
Constraints: Applicable project instructions and user requirements.
Deliverables: The files, findings, and validation evidence to return.
Done when: Observable criteria for accepting the result.
```

Look up facts and paths in the workspace before you dispatch. Include the relevant project guidance in the brief, or point to instruction files the child can read. Ask the user for a missing decision only when it changes the assignment and you can't infer it.

Done when: every field of the brief contains a resolved fact, path, or criterion.

## 2. Resolve the target

The **target selection** is everything the user said about how the child should run. Pull it out of the request, then match each part against `orchestrator_capabilities`, which reads the same live catalog as the T3 composer. A T3-owned child also needs `appOwnedSubagents` in that response.

| The user says | `delegate_task` field | Resolve it to |
| --- | --- | --- |
| A harness: "Claude", "Claude Code", "Codex" | `target.providerInstanceId` | The provider whose `displayName` or `driverKind` matches and that has `canRunChildTask: true`. If it differs from the parent's `inheritedProviderInstanceId`, it also needs `canRunCrossProviderChildTask: true`. |
| A model: "Opus 5.5", "GPT 6.1" | `target.model` | The `id` of the model whose `label` matches, within that provider. |
| An effort: "Medium", "High", "Extra High" | `target.options` | The model's reasoning option, set to the value whose label matches. The option id differs by provider: `effort` on Claude, `reasoningEffort` on Codex. |
| Other options: "fast mode", "1M context" | `target.options` | The matching option the model advertises. |
| Permissions: "Full Access", "auto-accept edits", "approval required", "auto" | `runtimeMode` | `full-access`, `auto-accept-edits`, `approval-required`, `auto` |
| "Plan mode" | `interactionMode` | `plan` |

- **Unstated parts are inherited.** Leave them out and T3 uses the parent's setting. If the user names only a model, the harness is that model's provider.
- **Use catalog values only.** Read the ids and values from the catalog every time. The ids in the examples below come from one install, and custom provider instances carry their own ids.
- **Ask when a name is ambiguous.** If a name matches more than one model ("GPT 6" matches several), ask the user which one they mean. This includes option values: on Claude, "Ultra" can mean `ultracode` or `ultrathink`. `ultracode` runs multi-agent workflows; select it only when the user names it, and tell them it conflicts with a brief that forbids further delegation.
- **Runtime modes are per provider.** When a provider lists `runtimeModes`, the requested mode must be one of them; a provider without the list offers every mode. `delegate_task` refuses a mode outside the list and steps an inherited mode down to the broadest one offered, so put the effective mode in the selection line. `t3_thread_launch` doesn't check: a launched thread whose provider lacks the mode runs as `approval-required`. Before launching, resolve a listed mode with the user, or stop.
- **Projects can turn a provider off.** `orchestrator_capabilities` reflects the machine; a project can still turn an instance off. Treat "is disabled for project" from a dispatch, launch, or send as an unusable target.
- **Report targets you can't use.** That covers a disabled provider, a missing model, an effort the model doesn't advertise, a runtime mode the provider doesn't list, a provider the project turned off, and `canRunChildTask: false`. Report the provider's `constraints` or the error and stop. Substituting a different target needs the user's approval.
- **Pick a harness when the user doesn't name one.** If the user asks for "another harness" without saying which, choose an enabled provider that differs from the parent's and state your choice.

The two delegations at the top of this skill resolve to:

```json
{"target": {"providerInstanceId": "claudeAgent", "model": "claude-opus-5-5", "options": {"effort": "medium"}}, "runtimeMode": "full-access"}
{"target": {"providerInstanceId": "codex", "model": "gpt-6.1-sol", "options": {"reasoningEffort": "high"}}, "runtimeMode": "full-access"}
```

**T3 or native subagents.** Use `delegate_task` for cross-harness work, for children the user explicitly wants owned by T3, and for any selection the native subagent tool can't fully express, including model, effort, and runtime mode. Native subagents are suitable only for same-provider work where they support the whole selection. Follow the active harness's delegation rules.

Done when: you can write the selection as one line, **provider · model · options · runtime mode**, where each part is either resolved from the catalog or marked as inherited. Tell the user that line before you dispatch.

## 3. Dispatch and track

Call `delegate_task` with:

- `task`: the brief
- `title`: a short label for the child thread
- `target`, `runtimeMode`, `interactionMode`: from the selection in phase 2
- `role`: the closest of `implementation`, `research`, `review`, `design`, `test`, `general`
- `mode="async"`: use `wait` only when this turn can't continue without the result. A wait can return while the child still runs, with `waitTimedOut`, `hasPendingQuestion`, or `pendingApproval` set. Keep the `taskId`, and handle a question or approval as [Blocked children](#waiting) describes.
- `clientRequestId`: distinct for each assignment or review round, and reused unchanged when retrying that same dispatch. If a dispatch response is lost, retry with the same key so you don't create a second child.

### Workspace

- **Shared checkout** (the default). The child works in this thread's checkout. Give concurrent writers disjoint file ownership.
- **Own worktree.** `isolation: "worktree"` gives the child a checkout of this thread's last commit, on a branch T3 names, after the T3 project's setup script runs. Commit what the child needs first: uncommitted edits stay behind. When the worker needs a base or branch you choose, or the setup script `AGENTS.md` names, launch it instead, as [Launched workers](references/launched-workers.md) describes.

Record the returned `taskId` together with the selection line. For native subagents, record their native agent identifier and use the native lifecycle tools.

### Waiting

Keep doing independent parent work while the child runs. Then wait in one of these ways only:

| Waiting for | Do this |
| --- | --- |
| A T3 child | End the turn. Tell the user which `taskId`s are running. T3 wakes you with a notification when each one finishes. |
| A child's result needed later in this same turn | One `task_status` call, or dispatch with `mode="wait"` |
| A shell process, such as a validation run or a failed child's leftover test run | The harness's background waiting tool from the [harness table](#harness-notes). It notifies you when the process exits. |
| A launched worker | End the turn. The background CLI send that delivered its round wakes you, as [Launched workers](references/launched-workers.md) describes. |

If a wait times out, the child is still running: follow the existing task rather than dispatching a copy.

**Blocked children.** A child or worker can stop to wait for an answer. For `hasPendingQuestion`, read the question with `t3_pending_request_read` on its thread, then answer it from the brief with `t3_pending_request_respond`, or ask the user. No T3 tool can grant a `pendingApproval`: tell the user and link the thread as `[title](t3-thread://v1/<threadId>)`. A message typed in that thread's composer declines the request and redirects the agent. Either way it keeps running, and a child's completion still wakes you.

Done when: every assignment has a `taskId`, or a launched worker's `threadId`, recorded with its selection.

## 4. Assess the result

**Reading status.** When a completion notification arrives, call `task_status` once for that `taskId` and read its `summary`. Accept only `workState: result_available` with `hasPendingChildRuns: false`. `waiting_for_children` means the child's turn ended but work it started still runs. Reading a terminal result acknowledges its automatic delivery.

**Failed children.** A child can fail for reasons outside its work, such as a rate limit or a frozen host; its `summary` names the cause. It may leave processes running in its workspace. Check for them before you act. If there are any, wait on them with the background waiting tool, then inspect what the child changed. Retry the same `clientRequestId` only when the dispatch itself was lost. When the child ran and then failed, start a new round.

**Checking the work.** Compare the deliverables and evidence against the brief's "Done when" criteria. Inspect the artifacts the child produced and run any remaining integration checks. Resolve missing evidence or open objections before you present the work as complete.

**Another round.** For another review round, or any round that should start fresh, call `delegate_task` again. Send the original brief, the prior findings, the responses, and any unresolved objections, with a new `clientRequestId` for the round. Track the new `taskId`. A review round never goes to the old `childThreadId`.

A correction that needs the same child's conversation can go to its `childThreadId` instead, once the original task is terminal. First cancel any stale turn that `t3_queue_list` shows on that thread with `t3_queue_cancel`: a send resumes a held queue, so the old turn would run first. Then call `t3_thread_send` with `mode: "queue"` and a new `clientRequestId` for the round, reused unchanged on retries. T3 creates a fresh task in that child thread and returns its `taskId`; its completion notifies you like any child, and the original result stays unchanged. Write the message so the round stands on its own: the findings, what not to change, and the brief's Deliverables and Done-when fields. If the send returns no `taskId`, start the round with `delegate_task` instead.

**Cancelling.** Use `task_cancel` when the user asks you to stop an owned task, or when the authorized workflow requires it. Cancelling also stops the task's descendants and any later runs on its backing thread. Results that were already published stay available. A task whose child had only background work left can report `completed` after `task_cancel`; record it as cancelled and don't accept its summary.

For launched workers, read, correct, and cancel as [Launched workers](references/launched-workers.md) describes; the rest of this phase still applies.

Done when: every assignment is accepted, cancelled, or still running, with evidence for the accepted ones.

Finish with the outcome, the delegate's selection line, the validation evidence, and any unresolved work. If a task is still running, give its `taskId` and state, and describe it as running.
