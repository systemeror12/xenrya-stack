---
name: interrogation
description: "Use for \"interrogate\", \"adversarial review\", \"multi-model review\", \"challenge this\", \"stress test this code\", \"find blind spots\", or \"tear this apart\". Multiple LLM reviewers challenge changes from independent angles."
disable-model-invocation: true
metadata:
  upstream-author: "Lauren Tan (poteto)"
  upstream-project: "pstack"
  upstream-source: "https://github.com/cursor/plugins/tree/d0ef80d86795816da932a153458c5dbe192d294e/pstack/skills/interrogate"
  upstream-license: "MIT"
  adaptation: "T3 Code MCP delegation"
---

# Interrogation

Delegate one reviewer per selected model to adversarially review code changes. Each model gets the same prompt and rubric. The adversarial signal comes from model diversity, not assigned personas.

The deliverable is a synthesized verdict. Do NOT auto-apply changes.

The adapted pstack references retain their [MIT license and copyright notice](references/LICENSE.pstack).

## Step 1, Determine Scope

Identify what to review from context:

- If the user points at specific files or a diff, use that
- If on a feature branch, identify the appropriate base branch and use `git diff BASE...HEAD` for the committed changeset
- If the user's message references recent work, gather the relevant files
- If the user names several PRs ("interrogate the 3 PRs"), review each PR as its own scope. For each one, record its number, base, head commit, and checkout or worktree path, and freeze its diff to a file such as `/tmp/interrogation/pr-<N>.diff`

Include staged, unstaged, and untracked changes when they are part of the requested scope. Capture the checkout path, base/head commits where relevant, diff or file contents, and surrounding context before dispatch. Every reviewer must receive the same review snapshot and applicable repository instructions.

## Step 2, State the Intent

Before spawning reviewers, state the intent explicitly. Derive this from:

- The user's message
- Commit messages
- PR description if one exists
- The code itself

Write one clear paragraph for each scope; with several PRs, each PR's intent comes from its ticket and description. A PR's review guide is not a source: an agent wrote it. If you're unsure about the intent, ask the user before proceeding.

## Step 3, Delegate Reviewers

Read and follow [delegate-subagents](../../orchestration/delegate-subagents/SKILL.md), or its installed copy from the active harness's skill catalog. Apply its instructions with the available tools; a harness-specific Skill tool is not required.

### Where each review runs

Reviewers are `delegate_task` children, so they inherit the checkout of the thread that dispatches them, and T3 labels them with that thread's branch. Run each scope's review from a thread bound to that scope's checkout:

- **Scope in this thread's checkout** (the current branch, or local files): you are the lead. Do the rest of Step 3 and Steps 4–5 here.
- **Scope in another checkout** (a PR in its own worktree, such as the PRs from `swarm-tickets`): you are the parent. Resolve the reviewer roster below, then launch one **lead thread** per PR, bound to that PR's checkout with `existing_worktree`, as [Launched workers](../../orchestration/delegate-subagents/SKILL.md#launched-workers) describes. Each lead dispatches that PR's reviewers and judges their findings. Launch a fresh lead rather than reusing the thread that wrote the code, so the author doesn't judge its own review.

Title each lead `Interrogate PR #<N> (<ticket>) [interrogate-<date>-pr<N>-r1]`, and send it this brief:

```text
Read the skill at <absolute path to interrogation/SKILL.md> and act as the lead
for one scope. A parent thread launched you: finish everything in this one turn.

Scope: PR #<N> (<ticket>), base <base> at <commit>, head <commit>, checkout
<absolute path>. This thread is bound to that checkout. Frozen diff: <path>.
Intent: <the Step 2 paragraph>.
Reviewers: <one line per reviewer: provider · model · options>.
Repository guidance and glossary: <paths>.

Do Step 3 for this scope only, with one change: dispatch every reviewer in one
message of parallel delegate_task calls with mode "wait" and timeoutMs 1800000,
so the reviews finish inside this turn. Count a reviewer that returns
waitTimedOut as incomplete coverage and give its taskId. Then do Steps 4 and 5
and return the verdict in the Output Format, starting with
"## Verdict: PR #<N>". Don't edit the repository, apply fixes, commit, push,
or touch PRs or databases.
```

The leads wait on their reviewers with `mode: "wait"` because the parent's `t3_thread_wait` returns when the lead's turn ends. A lead that ended its turn to wait for notifications would look finished before its reviews were in.

As the parent, wait on each lead and read its verdict, the last assistant message, as Launched workers describes. A lead that failed or returned no verdict is missing coverage for its PR. Then go to the Output Format with the leads' verdicts.

### Dispatching reviewers

The parent resolves the roster (the next two paragraphs) before it launches leads, and a launched lead uses the roster in its brief. Everything after the roster is the lead's work.

Call `orchestrator_capabilities` and resolve the user's requested models, or a reviewer roster in applicable project instructions, to live `providerInstanceId` and model IDs. An existing `interrogate reviewers` list can supply preferences; it is not a separate model catalog. Check child-task support, cross-provider constraints, and supported model options. Treat `auto` or `inherit-parent` as a request to inherit the caller's selection, rather than as a literal model ID.

Without a requested roster, choose two distinct capable models, preferring different providers. Use a smaller roster if availability requires it, including a provider the project turned off ("is disabled for project"), and report the reduced diversity. State the selected providers/models before dispatch. Report an unavailable requested model instead of silently substituting a family default. Refresh capabilities and correct actionable dispatch errors; retain valid reviewers and identify any unavailable entries.

Read [the reviewer prompt](references/reviewer-prompt.md), [review rubric](references/rubric.md), and [code-quality lens](references/code-quality-review.md). Fill the prompt with the intent, checkout path, frozen review scope, surrounding context, repository guidance, and the domain glossary: `GLOSSARY.md`, or the glossaries `GLOSSARY-MAP.md` lists for the touched contexts. Insert the full rubric and code-quality lens into their placeholders. Structural improvements are review proposals; reviewers must leave the implementation unchanged.

Reviewers receive only their supplied task prompt, so include the needed context or absolute paths to accessible snapshot artifacts. Keep each initial review independent of the other reviewers' findings and send the same filled prompt to every selected model. Don't send reviewers a PR's review guide: it would steer every reviewer the same way.

Use T3-owned child tasks through `delegate_task`, with `role:"review"`, `mode:"async"`, and inherited permission modes. Pass the shared brief as `task` and the resolved selection as `target:{providerInstanceId,model}`. For an inherited selection, omit the corresponding target overrides. With several PRs, give each PR its own reviewers, one per selected model, with that PR's intent and diff. Title each task `Interrogate PR #<N> (<ticket>)` and give it a `clientRequestId` such as `interrogate-<date>-pr<N>-<model>-r1`. Launch independent reviewers together when the harness supports parallel tool calls. Retain one stable `clientRequestId` per reviewer/round and every returned `taskId` with its actual provider/model.

The brief must prohibit repository edits, applying fixes, commits, pushes, PR creation, migrations, and database writes. `role:"review"` labels the task; it does not enforce a filesystem restriction, and T3 has no `readonly` or `subagent_type` argument. Reviewers are always `delegate_task` children of their lead: never create reviewers with `t3_thread_launch` or `create_threads`.

Follow `delegate-subagents` for completion notifications, `task_status` result collection, cancellation, and any additional review rounds. When only reviewers remain, a lead in its own thread ends the turn and resumes on their completion notifications; a launched lead follows its brief. Collect published results before issuing the verdict; a completed child turn with pending descendants is still unfinished work. Failed, cancelled, or unavailable reviewers must be reported as incomplete coverage.

## Step 4, Synthesize

As results come back, build a unified picture:

1. **Parse all findings** from the reviewers
2. **Identify consensus**. Findings raised independently by multiple distinct models deserve closer inspection. Agreement helps prioritize investigation; verify the evidence before accepting the claim.
3. **Identify lone-model findings**. Still worth reading, but weight accordingly.
4. **Deduplicate**. Different models may describe the same issue differently. Merge these and note which models raised it.
5. **Note disagreements**. If one model flags something and another explicitly says the opposite, that's useful context for the verdict.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator.

Read [the lead-judgment framework](references/lead-judgment.md) before categorizing findings. Apply the conversation context, project constraints, and pragmatic filtering that independent reviewers may lack. Verify each actionable claim against the reviewed snapshot and stated intent. A concrete lone-model finding can outweigh unsupported consensus. Missing coverage is not an endorsement. When a reviewed PR has a review guide (`read_pull_request_guide`), you may use its Look closely stops as a coverage check: a stop that no finding covers is one to check yourself.

Categorize every finding using these buckets:

- **Act on**. Real issues affecting correctness, security, or maintainability given the actual goals. These would block a real PR.
- **Consider**. Legitimate points, but you're not sure they outweigh the cost of addressing them right now. Worth the user's attention.
- **Noted**. Technically valid but not actionable. Context-dependent, premature optimization, or low-impact given the current stage.
- **Dismissed**. Wrong, nitpicky, or missing context. Brief explanation why.

For each finding, include:

- Which model(s) raised it
- The category (act on / consider / noted / dismissed)
- A one-line rationale for the categorization

## Output Format

Present the verdict in this structure. With several PRs, start with a table of PR, lead thread, reviewers, and Act On count, then give one full verdict per PR. Link each lead thread as `[title](t3-thread://v1/<threadId>)`. Link a PR's review guide when one exists.

### Intent

> [The stated intent paragraph from Step 2]

### Reviewers

- Reviewer [label]: [provider/model], [status], [N findings when completed] (one bullet per reviewer)

Identify omitted reviewers, unavailable targets, and failed tasks. Distinguish the reviewed snapshot from any later checkout changes.

### Act On

[Findings that should be addressed. For each: description, which models raised it, why it matters.]

### Consider

[Findings worth thinking about. For each: description, which models raised it, tradeoff involved.]

### Noted

[Valid but low-priority. Brief list.]

### Dismissed

[Rejected findings with brief rationale.]

### Agreement Map

[Where did models agree, where did they diverge, and what does the pattern of agreement/disagreement tell us?]

## After the Verdict

Stop after the verdict. Apply nothing until the user asks. When the user asks for fixes:

- If the PRs came from `swarm-tickets`, its phase 7 (Revise) does the fixes. It sends each PR's Act On findings to that ticket's worker thread as a new round, not to the lead thread, then runs `pr` again for each changed PR.
- Otherwise, follow `delegate-subagents` phase 4 for a correction round, or fix the code yourself when the user asks you to.

In both cases, list the findings being fixed and the ones left alone, so the fixer changes only what was accepted.
