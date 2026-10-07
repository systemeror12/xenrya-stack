---
name: delegate-subagents
description: "Delegate a specific task to another harness or subagent. Use when the user requests cross-harness work, a T3-owned child task, or scoped work by subagents."
---

# Delegate Subagents

Turn the user's request into a bounded assignment, choose the requested harness, and assess the returned work. The parent owns integration and the final answer.

## Define the assignment

Extract one concrete outcome for each delegate. Give it enough work to produce a useful result without overlapping another writer's scope. Split into multiple assignments only when the user requests subagents or the active instructions authorize that delegation.

Write a self-contained brief. T3 children receive the supplied prompt without the parent conversation history:

```text
Task: The specific outcome to produce.
Workspace: The absolute checkout path and relevant files or artifacts.
Context: Required facts, excerpts, prior findings, and decisions.
Scope: Permitted changes, ownership boundaries, or a read-only assignment.
Constraints: Applicable project instructions and user requirements.
Deliverables: The files, findings, and validation evidence to return.
Done when: Observable criteria for accepting the result.
```

Resolve facts and paths from the workspace before dispatch. Include the relevant project guidance in the brief or point to accessible instruction files. Ask for a missing decision only when it changes the assignment and cannot be inferred.

## Select the harness

Call `orchestrator_capabilities` to resolve the requested harness to an enabled `providerInstanceId`, model, and supported options. Check its child-task and cross-provider capabilities. Honor an explicit model choice; report an unavailable target instead of silently substituting one. When the user requests another harness without naming it, choose an available harness different from the caller and state the selection.

Use `delegate_task` for cross-harness work, explicitly T3-owned children, or a selected model that native subagent tools cannot run. For same-provider work, prefer native subagents when they support the selected model. Follow the active harness's delegation rules.

T3 delegation inherits the calling checkout and has no `workspaceStrategy` argument. Give concurrent writers disjoint file ownership. A delegated task is a child of this conversation; independent top-level conversations require their own explicit user request.

## Dispatch and track

For T3, pass the brief as `task`, set `target` from the live catalog, choose the appropriate `role`, and prefer `mode="async"`. Use a distinct `clientRequestId` for each assignment or review round, stable across retries of that assignment.

Retain the returned `taskId` and chosen provider/model. In Codex code mode, the callable tool is `tools.mcp__t3_code__delegate_task(args)`; other harnesses may normalize the MCP prefix differently. For native subagents, retain their native agent identifier and use their lifecycle tools.

Continue independent parent work while the child runs. When only child work remains, end the turn so T3 can deliver its completion notification. Use `task_status` when the result is needed mid-turn. A wait timeout leaves the child running; follow the existing task instead of dispatching another copy. If a dispatch response is lost, retry with the same request key.

## Assess the result

For T3, use `task_status` to distinguish active work, `waiting_for_children`, and `result_available`. Read the published `summary`; reading a terminal result acknowledges automatic delivery. A completed child turn with live nested work is not a completed delegated task.

Check the deliverables and evidence against the brief's acceptance criteria. Inspect produced artifacts and perform any remaining integration checks. Resolve missing evidence or objections before presenting the work as complete.

For another delegated review round, call `delegate_task` again with the original brief, prior findings, responses, unresolved objections, and a new round request key. Track its new `taskId`. The old `childThreadId` is backing storage, not the target for another review round through `t3_thread_send`.

Use `task_cancel` when stopping an owned task is requested or required by the authorized workflow. It also stops descendants and later backing-thread runs; published results remain available.

Finish with the outcome, delegate identity, validation evidence, and unresolved work. If the task is still running, report its identifier and state; do not describe it as finished.
