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

- **Children come from `delegate_task`, except launched workers.** Don't create a child with `t3_thread_launch` or `create_threads`. Those make top-level threads that never notify this one. Continue a child only as phase 4's [Another round](#4-assess-the-result) describes. The one exception is a **launched worker**: a worker that needs its own workspace binding in T3, such as a worktree, or one that a calling skill (`swarm-tickets`, `interrogation`) tells you to launch. A `delegate_task` child inherits this thread's checkout, so T3 would label it with the wrong branch. Follow [Launched workers](#launched-workers) for those.
- **Wait by ending your turn.** A child's completion wakes this thread with a notification. Don't run `sleep`, don't poll `task_status` in a loop, and don't call `t3_thread_wait` on a child's thread. Launched workers are the exception: nothing wakes you for them, so you wait on them with `t3_thread_wait` as [Launched workers](#launched-workers) describes.

The workflow has four phases: **define → resolve target → dispatch → assess**. Other skills, such as `swarm-tickets`, write their own briefs and then follow phases 2–4 here for their workers.

## Harness notes

This skill runs on both Claude Code and Codex. The instructions use bare T3 tool names. Map them to your harness like this:

| | Claude Code | Codex |
| --- | --- | --- |
| T3 tool names | `mcp__t3-code__<tool>` | `mcp__t3_code__<tool>`; in code mode, `tools.mcp__t3_code__<tool>(args)` |
| T3 tools missing | Listed as deferred: load the schemas with ToolSearch, e.g. `select:mcp__t3-code__orchestrator_capabilities,mcp__t3-code__delegate_task,mcp__t3-code__task_status,mcp__t3-code__task_cancel` | Make one direct call to `orchestrator_capabilities` before you conclude T3 is unavailable |
| Native subagents | Agent tool | Codex native subagents |
| Wait on a shell process | Bash with `run_in_background: true` running an `until` loop, or the Monitor tool | A background terminal session |

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
- `mode="async"`: use `wait` only when this turn can't continue without the result. On `wait`, `timeoutMs` only limits how long the parent waits; the child keeps running. If the call returns `waitTimedOut`, keep the `taskId` and follow up with `task_status`.
- `clientRequestId`: distinct for each assignment or review round, and reused unchanged when retrying that same dispatch. If a dispatch response is lost, retry with the same key so you don't create a second child.

### Workspace

`delegate_task` has no workspace parameter. The child works in whatever directory its brief names, and its shell may start in the parent's checkout.

- **Shared checkout** (the default). Give the parent's checkout path, and give concurrent writers disjoint file ownership.
- **Own worktree.** When a worker needs its own branch or isolated state, create the worktree yourself (`git worktree add -b <branch> <path> <base>`) and run the repository's worktree setup script in it, one worktree at a time. Then launch the worker bound to it, as [Launched workers](#launched-workers) describes, instead of calling `delegate_task`.

A launched worker is still your worker: you own its brief, waiting, acceptance, and cancellation. Any other top-level conversation needs its own explicit request from the user.

Record the returned `taskId` together with the selection line. For native subagents, record their native agent identifier and use the native lifecycle tools.

### Waiting

Keep doing independent parent work while the child runs. Then wait in one of these ways only:

| Waiting for | Do this |
| --- | --- |
| A T3 child | End the turn. Tell the user which `taskId`s are running. T3 wakes you with a notification when each one finishes. |
| A child's result needed later in this same turn | One `task_status` call, or dispatch with `mode="wait"` |
| A shell process, such as a validation run or a failed child's leftover test run | The harness's background waiting tool from the [harness table](#harness-notes). It notifies you when the process exits. |
| A launched worker | `t3_thread_wait` without ending the turn, as [Launched workers](#launched-workers) describes |

If a wait times out, the child is still running: follow the existing task rather than dispatching a copy.

Done when: every assignment has a `taskId`, or a launched worker's `threadId`, recorded with its selection.

## 4. Assess the result

**Reading status.** When a completion notification arrives, call `task_status` once for that `taskId`. It reports a `workState` of active work, `waiting_for_children`, or `result_available`. Read the published `summary`. Reading a terminal result acknowledges its automatic delivery. A finished child turn that still has live nested work, or `hasPendingChildRuns: true`, is not a finished delegated task.

**Failed children.** A child can fail for reasons outside its work, such as a rate limit, and it may leave processes running in its workspace. Check for them before you act. If there are any, wait on them with the background waiting tool, then inspect what the child changed. Retry the same `clientRequestId` only when the dispatch itself was lost. When the child ran and then failed, start a new round.

**Checking the work.** Compare the deliverables and evidence against the brief's "Done when" criteria. Inspect the artifacts the child produced and run any remaining integration checks. Resolve missing evidence or open objections before you present the work as complete.

**Another round.** For another review round, or any round that should start fresh, call `delegate_task` again. Send the original brief, the prior findings, the responses, and any unresolved objections, with a new `clientRequestId` for the round. Track the new `taskId`. A review round never goes to the old `childThreadId`.

A correction that needs the same child's conversation can go to its `childThreadId` instead, once the original task is terminal. Call `t3_thread_send` with `mode: "queue"` and a new `clientRequestId` for the round, reused unchanged on retries. T3 creates a fresh task in that child thread and returns its `taskId`; its completion notifies you like any child, and the original result stays unchanged. Write the message so the round stands on its own: the findings, what not to change, and the brief's Deliverables and Done-when fields. If the send returns no `taskId`, start the round with `delegate_task` instead.

**Cancelling.** Use `task_cancel` when the user asks you to stop an owned task, or when the authorized workflow requires it. Cancelling also stops the task's descendants and any later runs on its backing thread. Results that were already published stay available. A task whose child had only background work left can report `completed` after `task_cancel`; record it as cancelled and don't accept its summary.

For launched workers, read, correct, and cancel as [Launched workers](#launched-workers) describes; the rest of this phase still applies.

Done when: every assignment is accepted, cancelled, or still running, with evidence for the accepted ones.

Finish with the outcome, the delegate's selection line, the validation evidence, and any unresolved work. If a task is still running, give its `taskId` and state, and describe it as running.

## Launched workers

A launched worker is a top-level T3 thread that you start with `t3_thread_launch` and follow as your own worker. T3 binds it to its workspace, so its thread shows the real branch. Use one only when the worker needs its own workspace binding or a calling skill says to launch it. Everything else stays on `delegate_task`.

In Claude Code, load the schemas in one ToolSearch call: `select:mcp__t3-code__t3_thread_launch,mcp__t3-code__t3_thread_list,mcp__t3-code__t3_thread_wait,mcp__t3-code__t3_thread_read,mcp__t3-code__t3_thread_send,mcp__t3-code__t3_thread_interrupt,mcp__t3-code__t3_pending_request_list,mcp__t3-code__t3_pending_request_respond,mcp__t3-code__t3_queue_list,mcp__t3-code__t3_workflow_stop`.

**Before launching.**

- **Modes.** A launched thread can't run with broader runtime or interaction modes than this thread. `orchestrator_capabilities` reports this thread's `runtimeMode` and `interactionMode`. If the selection asks for more, such as full-access workers from an auto-accept-edits parent, report it and stop. Also check the runtime mode against the provider's `runtimeModes`, as phase 2 describes: `t3_thread_launch` doesn't.
- **Workspace.** The checkout must already exist and its setup must have passed. T3's own preparation runs only a setup script saved in the T3 project, not the one the repository's `AGENTS.md` names, so create worktrees and run setup yourself, one at a time. Bind a worktree with `existing_worktree`. Use `{"type": "root"}` only for the project's main checkout.

**Launch.**

```json
{
  "title": "<label> [<run tag>]",
  "message": "<the brief>",
  "modelSelection": {"instanceId": "<providerInstanceId>", "model": "<model id>", "options": {"effort": "<value>"}},
  "runtimeMode": "<runtime mode>",
  "workspaceStrategy": {"type": "existing_worktree", "worktreePath": "<absolute path>", "branch": "<branch>"}
}
```

`modelSelection` carries the phase 2 selection, with `instanceId` in place of `providerInstanceId`. Leave out the parts the selection inherits. The run tag, such as `swarm-20261010-a-467-a1`, must be unique, because `t3_thread_launch` has no retry key. Record the returned `threadId` with the selection and a read position of 0. Tell the brief to finish in one turn and to report a blocker in its result rather than ask a question, because a worker that ends its turn early looks finished to you.

**Lost response or error.** Call `t3_thread_list` with `titleContains: "<run tag>"` before you launch again. If the thread exists, record it and follow it. Launch again only when it doesn't exist.

**Waiting.** Nothing wakes you when a launched worker finishes, so don't end your turn while one is running. Call `t3_thread_wait` on one running worker at a time, with `timeoutMs: 600000`. When it returns, handle that worker, then wait on the next running one. A worker that finished in the meantime returns at once.

- `timedOut: true` means the worker is still running. Check its status with `t3_thread_list`. If it is `waiting`, call `t3_pending_request_list` and answer a listed question from the brief with `t3_pending_request_respond`. An empty list means the worker is waiting on a permission approval these tools can't grant: tell the user, link the thread as `[title](t3-thread://v1/<threadId>)`, and keep waiting on the other workers. Otherwise call `t3_thread_wait` again.
- When it returns `interrupted`, `failed`, or `cancelled`, or returns at once without a terminal status, check the thread with `t3_thread_list` before you act. After a server restart T3 may continue a thread on its own, up to three times in a row. If the thread is `preparing`, or a newer run is `queued`, `starting`, or `running`, wait again without `runId`.
- If your turn ends anyway, because the user interrupted, the harness ended it, or a server restart cut it (T3 then sends this thread "Continue where you left off."), start the next turn with `t3_thread_list` and `t3_thread_read` for every recorded `threadId`, update your records, and keep waiting.

**Reading the result.** Call `t3_thread_read` with `view: "messages"` and `afterPosition` set to the recorded read position. The worker's report is the last assistant message. If it is truncated, continue with its `itemId` and `textOffset` until `nextTextOffset` is null. Record `nextPosition` as the new read position. A launched worker is **settled** when its newest run is terminal (completed, failed, interrupted, or cancelled) and `t3_queue_list` shows nothing queued on its thread. Then assess the result as in phase 4.

**Another round.** Send the correction to the same thread with `t3_thread_send`, `mode: "queue"`, and a new `clientRequestId` for the round, reused unchanged on retries. The worker keeps its earlier context, but write the message so the round stands on its own: the findings, what not to change, and the brief's Validation, Scope, and Return fields. A round queued on a provider the project turned off is held, not run, so confirm with `t3_thread_list` that the thread left `queued` or `idle` before you wait on it. Then wait as above. Queue one round at a time. For a different target, launch a new thread on the same workspace with a new run tag.

**Failed workers.** Check for leftover processes in the worker's workspace and wait them out before you act, as in phase 4. When the worker ran and then failed, send the next round to the same thread.

**Cancelling.** Call `t3_thread_interrupt` with the `threadId` and a `clientRequestId`. It stops only the running turn. It doesn't hold queued turns or stop tasks the worker delegated, which is why you queue one round at a time and briefs forbid further delegation. Then read the thread with `t3_thread_read` and `view: "activity"`, and stop each Claude workflow still running with `t3_workflow_stop` and its coordinator `subagentId`. Confirm with `t3_thread_list` that nothing is running before you release the worker's files.
