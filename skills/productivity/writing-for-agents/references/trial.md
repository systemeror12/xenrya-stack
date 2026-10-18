# Trial

The trial branch of [`writing-for-agents`](../SKILL.md): run the document on a cold agent and read the path it took. A trial settles what reading can't: whether a sentence is a no-op, whether a criterion holds against the rush, whether a pointer fires.

Follow `delegate-subagents` phases 2–4 to resolve the target, dispatch, wait, and accept. This file covers what to send and what to look for.

1. **Pick the reader.** Choose the weakest target that will run the document in practice: the effort the user runs it at (often Medium), and the other harness when the document runs on both. Done when each reader has a selection line resolved from `orchestrator_capabilities`.
2. **Pick the scenario.** Use a real request the document is for. Take it from a past thread when one exists (`t3_thread_search`). Done when every branch you changed has a scenario that reaches it.
3. **Contain it.** A trial follows the document, so it does what the document does. Contain it by what the document's actions touch:
   - local reads and edits: `delegate_task` with `isolation: "worktree"`, so the child works in its own checkout from this thread's commit;
   - writes beyond the checkout, such as the tracker, a push, a PR, or a database: `interactionMode: "plan"`, so the child lays out its path without acting, or a brief that names the step where the trial stops.

   Point the child at the edited document by absolute path. The installed skill is a symlink to the main checkout, and a worktree child starts from the last commit, without your uncommitted edits. Done when nothing the trial does can reach anything shared.
4. **Run and read.** Dispatch with `role: "test"`. Read the result, then the child's activity: `t3_thread_read` on its `childThreadId` with `view: "activity"`. The activity shows the tools it called and the files it opened: which pointers fired, which steps ran, and where it stopped. Done when you can list the path the run took, step by step.
5. **Compare.** Set that path against the one you wrote. For each divergence, find the line responsible: a weak pointer, a fuzzy criterion, a buried step, a no-op, or a prohibition the agent followed the wrong way. Fix the line and rerun that scenario. Done when the path matches, or the remaining divergence is in the report.
