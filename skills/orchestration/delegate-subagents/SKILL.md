---
name: delegate-subagents
description: "Delegate scoped work to a subagent on a chosen harness, model, and reasoning effort through T3 Code. Use when the user asks for a subagent, work on another harness (Claude, Codex), or a specific model or effort for delegated work."
---

# Delegate Subagents

You are the **parent**. You turn the user's request into a bounded assignment, run it on the harness and model the user picked, and check the result. With T3 Code's `delegate_task`, a child can run on any enabled provider, so the parent and child may use different harnesses, models, and efforts:

```text
Parent: Claude Opus 5.5 · High  ──delegate_task──▶  Child: Claude Opus 5.5 · Medium · full-access
Parent: Claude Opus 5.5 · High  ──delegate_task──▶  Child: Codex GPT-6.1-Sol · High · full-access
```

You own integration and the final answer. The workflow has four phases: **define → resolve target → dispatch → assess**. Other skills, such as `swarm-tickets`, write their own briefs and then follow phases 2–4 here for their workers.

## Harness notes

This skill runs on both Claude Code and Codex. The instructions use bare T3 tool names. Map them to your harness like this:

| | Claude Code | Codex |
| --- | --- | --- |
| T3 tool names | `mcp__t3-code__<tool>` | `mcp__t3_code__<tool>`; in code mode, `tools.mcp__t3_code__<tool>(args)` |
| T3 tools missing | Listed as deferred: load the schemas with ToolSearch, e.g. `select:mcp__t3-code__orchestrator_capabilities,mcp__t3-code__delegate_task,mcp__t3-code__task_status,mcp__t3-code__task_cancel` | Make one direct call to `orchestrator_capabilities` before you conclude T3 is unavailable |
| Native subagents | Agent tool | Codex native subagents |

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
- **Ask when a name is ambiguous.** If a name matches more than one model ("GPT 6" matches several), ask the user which one they mean.
- **Report targets you can't use.** That covers a disabled provider, a missing model, an effort the model doesn't advertise, and `canRunChildTask: false`. Report the provider's `constraints` and stop. Substituting a different target needs the user's approval.
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

The child works in the parent's checkout because `delegate_task` has no `workspaceStrategy`. Give concurrent writers disjoint file ownership. A delegated task is a child of this conversation. An independent top-level conversation needs its own explicit request from the user.

Record the returned `taskId` together with the selection line. For native subagents, record their native agent identifier and use the native lifecycle tools.

Keep doing independent parent work while the child runs. When only child work remains, end the turn, and T3 will deliver the child's completion as a notification. Call `task_status` when you need the result mid-turn. If a wait times out, the child is still running: follow the existing task rather than dispatching a copy.

Done when: every assignment has a `taskId` recorded with its selection.

## 4. Assess the result

**Reading status.** `task_status` reports a `workState` of active work, `waiting_for_children`, or `result_available`. Read the published `summary`. Reading a terminal result acknowledges its automatic delivery. A finished child turn that still has live nested work, or `hasPendingChildRuns: true`, is not a finished delegated task.

**Checking the work.** Compare the deliverables and evidence against the brief's "Done when" criteria. Inspect the artifacts the child produced and run any remaining integration checks. Resolve missing evidence or open objections before you present the work as complete.

**Another round.** To start another delegated round, such as a review or a correction, call `delegate_task` again. Send the original brief, the prior findings, the responses, and any unresolved objections, with a new `clientRequestId` for the round. Track the new `taskId`. The old `childThreadId` is only backing storage: sending it a message with `t3_thread_send` doesn't start a new round.

**Cancelling.** Use `task_cancel` when the user asks you to stop an owned task, or when the authorized workflow requires it. Cancelling also stops the task's descendants and any later runs on its backing thread. Results that were already published stay available.

Done when: every assignment is accepted, cancelled, or still running, with evidence for the accepted ones.

Finish with the outcome, the delegate's selection line, the validation evidence, and any unresolved work. If a task is still running, give its `taskId` and state, and describe it as running.
