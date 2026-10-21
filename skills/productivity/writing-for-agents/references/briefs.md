# Briefs

The brief branch of [`writing-for-agents`](../SKILL.md). A **brief** is text you send through a T3 tool to an agent that starts without your conversation:

| Tool | Field | Its reader |
| --- | --- | --- |
| `delegate_task` | `task` | A child of this thread, holding only this text |
| `t3 thread send` (CLI) | stdin | A launched worker's round, the first brief included |
| `t3_thread_send` | `message` | A child thread receiving another round, with its earlier context |
| `create_threads` | `prompt` | New top-level threads sharing this checkout |
| `schedule_task` | `prompt` | A future run that fires with nobody watching |
| `t3_queue_edit` | `text` | A queued message, rewritten before it runs |

`delegate-subagents` owns which tool to use and the brief's fields (Task, Workspace, Context, Scope, Constraints, Deliverables, Done when). `swarm-tickets` and `interrogation` own their worker and lead briefs. This file covers how to word any of them so the reader takes the path you meant.

## Stand alone

Every fact, path, and decision the work needs is in the brief, or behind a path the reader can open.

- **Absolute paths** for the workspace, the files, and any skill the reader follows.
- **Resolved facts** you already hold, such as the base commit, the baseline failures, or the worktree's ports, in place of instructions to find them again.
- **Paste or point.** Paste what every reader must see identically, or what may change underneath them, such as a review scope. Point at what is stable and reachable, such as `AGENTS.md` or a frozen diff file.
- **Glossary terms** for every domain concept, so the reader's searches hit the code.

## Name the overrides

A brief that points at a skill often changes one of its steps: the parent owns commits, or the parent runs the full suite. Name the step you override, in the skill's own words: "this overrides the commit/push/PR step in implement". `implement` checks for a parent's brief ("When a parent's brief started you"); an override the brief leaves unnamed loses to the skill's own step.

## Bound the run

A launched worker that ends its turn early looks finished to its parent, and a question it asks waits for an answer nobody may give. Say how the run ends:

- "Finish in this one turn: if you're blocked, report the blocker in your Return rather than asking a question."
- "Do the work yourself rather than delegating it to further workers," whenever the parent must be able to stop everything the worker started.
- "Stop every background process you started before you finish."

## Shape the Return

The parent reads the last assistant message and accepts the work by comparing it with the brief. Name the Return's fields in the order the parent checks them, mirroring Done when: the criteria met, the changed files, the exact checks and their results, and the blockers. A reviewer's Return also names its severity scale and the empty result: "If you have zero findings, say so."

## Another round

A round sent with `t3_thread_send`, or a fresh `delegate_task` for another review round, stands alone: the thread may have been compacted since round 1, and a fresh child remembers nothing. Open with the round and what came before ("This is round 2 (correction) for ticket #464. Round 1 is committed at …"). List what to fix, then what to leave unchanged, then repeat the original Validation, Scope, and Return.

## Scheduled prompts

A `schedule_task` prompt is a brief for every future run. A run bound to the scheduling thread (the default) lands with that thread's context. A run in a fresh thread starts cold, so write its prompt as a full brief.

- **Name the work and the quiet result.** Say which skill or steps a run follows, and what it reports when it finds nothing to do.
- **Filter at the trigger.** Give a webhook `filters` for the events a run handles, and `dedupe` for repeats: a `replayKey` such as `{{headers.x-github-delivery}}` drops redeliveries, and a `coalesceKey` such as `{{body.pull_request.number}}` folds a burst into one run with the latest payload. A request the prompt would only ignore belongs in a filter, not a prompt line.
- **Tell new work from work in flight.** Dedupe covers one window, and a run can still fire while earlier work runs. Say how a run recognises work that it or an earlier run already started.
- **Webhook data is data.** The request reaches the run only through placeholders such as `{{body.action}}`. Each value arrives framed as untrusted, and skill, file, or command mentions inside it do nothing. Keep every instruction in the prompt, and use placeholders only for values the steps read.
