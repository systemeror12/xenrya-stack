# Launched workers

The launched-worker branch of [`delegate-subagents`](../SKILL.md). A **launched worker** is a top-level T3 thread that you start with `t3_thread_launch` and follow as your own worker. T3 binds it to the workspace you choose, so its thread shows the real branch. Use one only when the worker needs a workspace `delegate_task` can't give it, or a calling skill says to launch it. It is still your worker: you own its brief, waiting, acceptance, and cancellation. Phases 2 and 4 of `delegate-subagents` still apply.

In Claude Code, load the schemas in one ToolSearch call: `select:mcp__t3-code__t3_thread_launch,mcp__t3-code__t3_thread_list,mcp__t3-code__t3_thread_wait,mcp__t3-code__t3_thread_read,mcp__t3-code__t3_thread_interrupt,mcp__t3-code__t3_pending_request_list,mcp__t3-code__t3_pending_request_read,mcp__t3-code__t3_pending_request_respond,mcp__t3-code__t3_queue_list,mcp__t3-code__t3_queue_cancel,mcp__t3-code__t3_workflow_stop`.

**Before launching.**

- **Modes.** A launched thread can't run with broader runtime or interaction modes than this thread. `orchestrator_capabilities` reports this thread's `runtimeMode` and `interactionMode`. If the selection asks for more, such as full-access workers from an auto-accept-edits parent, report it and stop. Also check the runtime mode against the provider's `runtimeModes`, as phase 2 describes: `t3_thread_launch` doesn't.
- **CLI.** Confirm `~/.t3/bin/t3 thread --help` runs. Without it, put the brief in `message` and wait on each worker with `t3_thread_wait` in this turn, one at a time.
- **Workspace.** The checkout must already exist and its setup must have passed. T3's own preparation runs only a setup script saved in the T3 project, not the one the repository's `AGENTS.md` names, so create worktrees and run setup yourself, one at a time. Bind a worktree with `existing_worktree`. Use `{"type": "root"}` only for the project's main checkout.

**Launch.**

```json
{
  "title": "<label> [<run tag>]",
  "modelSelection": {"instanceId": "<providerInstanceId>", "model": "<model id>", "options": {"<option id>": "<value>"}},
  "runtimeMode": "<runtime mode>",
  "workspaceStrategy": {"type": "existing_worktree", "worktreePath": "<absolute path>", "branch": "<branch>"}
}
```

`modelSelection` carries the phase 2 selection, with `instanceId` in place of `providerInstanceId`, and the options under their catalog ids. Leave out the parts the selection inherits. Leave out `message` too: the thread starts idle, and the brief goes in with the first send. The run tag, such as `swarm-20261010-a-467-a1`, must be unique, because `t3_thread_launch` has no retry key. Record the returned `threadId` with the selection and a read position of 0. Tell the brief to finish in one turn and to report a blocker in its result rather than ask a question, because a worker that ends its turn early looks finished to you.

**Lost response or error.** Call `t3_thread_list` with `titleContains: "<run tag>"` before you launch again. If the thread exists, record it and follow it. Launch again only when it doesn't exist.

**Send a round.** Every round, the brief included, goes in through T3's CLI (`t3`, or `~/.t3/bin/t3` when it isn't on PATH), started with the harness's background waiting tool at its longest timeout:

```bash
~/.t3/bin/t3 thread send <threadId> - --wait --json <<'BRIEF'
<the brief, or the round>
BRIEF
```

Then end the turn. The command exits when that round's turn ends, even when the round queued behind another, and the exit wakes you:

| Exit | Means | Do |
| --- | --- | --- |
| 0 | `status: completed` | Read the result, below. |
| 1 | The run failed | Follow Failed workers, below. |
| 2 | The worker waits for an answer | Handle it as [Blocked children](../SKILL.md#waiting) describes, then wait on it with `t3_thread_wait`, `timeoutMs: 600000`, in this turn. |

A send has no retry key, so never send a round twice. When a send exits any other way, the harness stops it, or a turn starts without its exit (T3 sends "Continue where you left off." after a server restart), check the thread with `t3_thread_list` and `t3_thread_read`. Read the result when its newest run is terminal. Otherwise wait with `t3_thread_wait` in this turn, without `runId`: T3 may continue a thread on its own after a restart, up to three times, and a round on a provider the project turned off stays `queued`.

**Reading the result.** Call `t3_thread_read` with `view: "messages"` and `afterPosition` set to the recorded read position. The worker's report is the last assistant message. If it is truncated, continue with its `itemId` and `textOffset` until `nextTextOffset` is null. Record `nextPosition` as the new read position. A launched worker is **settled** when its newest run is terminal (completed, failed, interrupted, or cancelled) and `t3_queue_list` shows nothing queued on its thread. Then assess the result as in phase 4.

**Another round.** Clear stale queued turns as phase 4's [Another round](../SKILL.md#4-assess-the-result) describes, then send the round as above. Write it so it stands on its own: the findings, what not to change, and the brief's Validation, Scope, and Return fields. Send one round at a time. For a different target, launch a new thread on the same workspace with a new run tag.

**Failed workers.** Check for leftover processes in the worker's workspace and wait them out before you act, as in phase 4. When the worker ran and then failed, send the next round to the same thread.

**Cancelling.** Call `t3_thread_interrupt` with the `threadId` and a `clientRequestId`. It stops only the running turn. It doesn't hold queued turns or stop tasks the worker delegated, which is why you queue one round at a time and briefs forbid further delegation. Then read the thread with `t3_thread_read` and `view: "activity"`, and stop each Claude workflow still running with `t3_workflow_stop` and its coordinator `subagentId`. Confirm with `t3_thread_list` that nothing is running before you release the worker's files.
