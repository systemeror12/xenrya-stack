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

Include staged, unstaged, and untracked changes when they are part of the requested scope. Capture the checkout path, base/head commits where relevant, diff or file contents, and surrounding context before dispatch. Every reviewer must receive the same review snapshot and applicable repository instructions.

## Step 2, State the Intent

Before spawning reviewers, state the intent explicitly. Derive this from:

- The user's message
- Commit messages
- PR description if one exists
- The code itself

Write one clear paragraph. If you're unsure about the intent, ask the user before proceeding.

## Step 3, Delegate Reviewers

Read and follow [delegate-subagents](../../orchestration/delegate-subagents/SKILL.md), or its installed copy from the active harness's skill catalog. Apply its instructions with the available tools; a harness-specific Skill tool is not required.

Call `orchestrator_capabilities` and resolve the user's requested models, or a reviewer roster in applicable project instructions, to live `providerInstanceId` and model IDs. An existing `interrogate reviewers` list can supply preferences; it is not a separate model catalog. Check child-task support, cross-provider constraints, and supported model options. Treat `auto` or `inherit-parent` as a request to inherit the caller's selection, rather than as a literal model ID.

Without a requested roster, choose two distinct capable models, preferring different providers. Use a smaller roster if availability requires it and report the reduced diversity. State the selected providers/models before dispatch. Report an unavailable requested model instead of silently substituting a family default. Refresh capabilities and correct actionable dispatch errors; retain valid reviewers and identify any unavailable entries.

Read [the reviewer prompt](references/reviewer-prompt.md), [review rubric](references/rubric.md), and [code-quality lens](references/code-quality-review.md). Fill the prompt with the intent, checkout path, frozen review scope, surrounding context, repository guidance, and the domain glossary: `GLOSSARY.md`, or the glossaries `GLOSSARY-MAP.md` lists for the touched contexts. Insert the full rubric and code-quality lens into their placeholders. Structural improvements are review proposals; reviewers must leave the implementation unchanged.

Reviewers receive only their supplied task prompt, so include the needed context or absolute paths to accessible snapshot artifacts. Keep each initial review independent of the other reviewers' findings and send the same filled prompt to every selected model.

Use T3-owned child tasks through `delegate_task`, with `role:"review"`, `mode:"async"`, and inherited permission modes. Pass the shared brief as `task` and the resolved selection as `target:{providerInstanceId,model}`. For an inherited selection, omit the corresponding target overrides. Launch independent reviewers together when the harness supports parallel tool calls. Retain one stable `clientRequestId` per reviewer/round and every returned `taskId` with its actual provider/model.

The brief must prohibit repository edits, applying fixes, commits, pushes, and PR creation. `role:"review"` labels the task; it does not enforce a filesystem restriction, and T3 has no `readonly` or `subagent_type` argument. Child reviews belong to this conversation and require no new top-level threads.

Follow `delegate-subagents` for completion notifications, `task_status` result collection, cancellation, and any additional review rounds. When only reviewers remain, end the turn and resume on their completion notifications. Collect published results before issuing the verdict; a completed child turn with pending descendants is still unfinished work. Failed, cancelled, or unavailable reviewers must be reported as incomplete coverage.

## Step 4, Synthesize

As results come back, build a unified picture:

1. **Parse all findings** from the reviewers
2. **Identify consensus**. Findings raised independently by multiple distinct models deserve closer inspection. Agreement helps prioritize investigation; verify the evidence before accepting the claim.
3. **Identify lone-model findings**. Still worth reading, but weight accordingly.
4. **Deduplicate**. Different models may describe the same issue differently. Merge these and note which models raised it.
5. **Note disagreements**. If one model flags something and another explicitly says the opposite, that's useful context for the verdict.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator.

Read [the lead-judgment framework](references/lead-judgment.md) before categorizing findings. Apply the conversation context, project constraints, and pragmatic filtering that independent reviewers may lack. Verify each actionable claim against the reviewed snapshot and stated intent. A concrete lone-model finding can outweigh unsupported consensus. Missing coverage is not an endorsement.

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

Present the verdict in this structure:

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
