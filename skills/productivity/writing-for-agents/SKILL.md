---
name: writing-for-agents
description: "Use for \"new skill\", \"edit a skill\", \"SKILL.md\", \"AGENTS.md\", \"CLAUDE.md\", \"write a brief\", or \"scheduled task prompt\". Writes documents agents consume, from skills to T3 briefs, so every run takes the same path through them."
---

# Writing for Agents

Write any document an agent consumes: a skill, an `AGENTS.md` or `CLAUDE.md`, a file a pointer reaches, or a brief you send through a T3 tool. The packaging differs, but the writing is the same. The goal is a **predictable** document: every run takes the same _path_ through it, even when the outputs differ.

Write for the **cold reader**, the weakest agent that will run the document. In this stack that may be Claude Code or Codex at Medium effort, holding only the document, what its pointers reach, and what it can look up with the shell and T3's tools. A brief's reader holds even less: a T3 child gets only the text you send.

## Documents

| Document | Also read |
| --- | --- |
| A skill: `SKILL.md`, its `references/`, and `agents/openai.yaml` | [`references/skills.md`](references/skills.md) |
| A brief: a `delegate_task` task, a `t3_thread_launch` message, a round sent with `t3_thread_send`, a `create_threads` prompt, or a `schedule_task` prompt | [`references/briefs.md`](references/briefs.md) |
| `AGENTS.md` or `CLAUDE.md` | `setup-xenrya-stack`, which owns the `## Agent skills` block |
| A spec, ticket set, or PR body | The skill that owns its format: `specs`, `to-tickets`, or `pr` |

An instructions file loads on every turn, so each of its lines is context load. Keep the pointers and the conventions an agent can't find by looking.

## Steps

1. **Gather.** Read the document, then what surrounds it:
   - every pointer that reaches it: search the repo, the instructions files, and the other skills for its name;
   - every document it points to, and the skills it takes work from or hands work to;
   - for a new skill, every skill in the stack: their conventions, their leading words, and the work each already owns;
   - the T3 tools the reader will call, in their current descriptions. Nightlies change them, so read them fresh rather than from another skill's copy. In Claude Code, load a deferred tool with ToolSearch to see its description;
   - for a fix, the run that went wrong: find it with `t3_thread_search`, then read what the agent did with `t3_thread_read` and `view: "activity"`. In Claude Code, load both with `select:mcp__t3-code__t3_thread_search,mcp__t3-code__t3_thread_read`.

   Done when you can name every pointer to the document, every document it points to, its cold reader, and, for a fix, the line the run misread.
2. **Place.** Put each piece of content on a rung of the [information hierarchy](#information-hierarchy). Done when what every branch needs is in the file, and what only some branches reach sits behind a pointer.
3. **Write.** Give each disclosed piece a [pointer](#context-pointers), each step a [completion criterion](#steps-and-completion-criteria), each recurring idea a [leading word](#leading-words), and each behaviour its positive target. Done when every step ends on a checkable `Done when` line and every pointer names its branches.
4. **Prune.** Run [Pruning](#pruning) over the whole document, sentence by sentence, not just over your edit. Done when every sentence changes behaviour against the default, each meaning has one home, and no line restates what a file, a command, or a T3 tool reports.
5. **Trial.** When the user asks for a trial, or the active instructions authorize delegation, run the document on a cold agent by following [`references/trial.md`](references/trial.md). Otherwise, name the trial you would run in the report: its reader and its scenario. Done when the trial's path matches the one you wrote, or every divergence is traced to its line and fixed; without a trial, when the report names one.
6. **Report.** Give the files changed, the pointers added or reworded, what you pruned, and the trial's result or the trial you propose.

## Context pointers

A **context pointer** is a line in the reader's context that names material outside it and says when to reach it. A skill's description is one. So is each line of the `## Agent skills` block, a link to `references/` inside a step, the "Read the skill at <path>" line that opens a brief, and each T3 tool's own description. The pointer's wording, not the material behind it, decides whether a run reaches the material. When a run misses something it needed, sharpen the pointer first; move the material inline only when sharpening fails.

A pointer says what the material is and names its **branches**: the distinct cases in which a run needs it.

- **Lead with the trigger.** The word that fires the pointer comes first: `Use for "open a PR", …` in a description, "For a release PR, follow …" in a step.
- **One trigger per branch.** A phrase earns its slot by naming a distinct branch, or because the user actually types it. Synonyms nobody types are one branch written twice.
- **Leave the rest to the body.** A pointer carries the trigger and one clause on what the material does.
- **Make it followable.** Give a path the reader can open from where it runs: a relative link to a sibling file, a skill's name with this repo's path as a fallback, an absolute path in a brief.

## The two loads

Every pointer and document spends one of two budgets:

- **Context load** is what always-loaded text costs the agent on every turn: a model-invoked skill's description, each line of `AGENTS.md` or `CLAUDE.md`, each T3 tool description the harness loads. It spends tokens and attention whether or not it fires.
- **Cognitive load** is what the human must remember: which user-invoked skills exist, and when to type `/swarm-tickets` or `$interrogation`. Spend it where the human's judgement matters, such as starting a batch; remove it where it doesn't.

Material behind a pointer costs only the pointer's line. Material with no pointer at all rides on the human remembering it.

## Information hierarchy

A document holds **steps**, the actions the agent takes in order, and **reference**, the rules and facts it consults on demand. Put each piece on one rung of a ladder, ranked by how soon the agent needs it:

1. **In-file step**: what the agent does, in order.
2. **In-file reference**: consulted on demand. A flat set of peers, such as `pr`'s Sections table, is a fine arrangement.
3. **Disclosed reference**: a separate file behind a pointer. It may sit in the skill's `references/`, in `docs/agents/` behind the Agent skills block, or in another skill.

**Progressive disclosure** moves a piece down the ladder so the top stays legible. Branching is the test: inline what every branch needs, and disclose what only some branches reach. `pr` keeps its steps inline and sends release PRs to `references/release.md` and screenshots to `references/before-after.md`, because only some PRs reach them. Reference left inline when it belongs lower buries the steps, and whether the agent attends to a buried step becomes a coin flip.

**Co-location** decides what sits beside a piece once it is placed. Keep a concept's definition, rules, and caveats under one heading: `delegate-subagents` keeps launching, waiting on, reading, correcting, and cancelling a launched worker in one file, `references/launched-workers.md`, and the skills that launch workers point at it.

**Sprawl** is a document too long even when every line is live. Attention thins over the excess. Cure it with the ladder: disclose reference, and split by branch, sequence, or reader.

## Steps and completion criteria

Every step ends on a `Done when` line, its **completion criterion**. Two properties make it work:

- **Clarity**: can the agent tell done from not done? A vague criterion ("the plan is clear") invites **premature completion**: the steps still ahead pull the agent past the one in front of it. Sharpen the criterion first. Only when it stays fuzzy and a run shows the rush, move the later steps across a real context boundary: a `delegate_task` child or a launched worker. Invoking another skill in the same thread leaves the later steps in context and hides nothing.
- **Demand**: how much it requires. "Every changed file falls under a Changes bullet or a Risk note" drives legwork that "write the Changes section" never asks for. Demand binds reference too: "every rule applied" sets the bar for a flat rule set.

The strongest criteria are checkable and exhaustive: "every selected ticket has a claim outcome in the ledger".

**Turn boundaries.** In T3, how a turn ends is part of the path. Ending the turn is how a parent waits, but only when something will wake it: a `delegate_task` child's notification, or the background CLI send that delivered a launched worker's round. When a workflow spans turns, say where each turn ends and what starts the next, as `swarm-tickets`' Turn map does.

## When to split

Splitting one document into two spends one of the loads, so split only when the cut pays for itself:

- **By sequence**: when the steps still ahead tempt the agent to rush the current one. The cut works only across a context boundary, as above. The reverse holds too: merging two sequences shows each step what follows it.
- **By invocation**: skills only. See [`references/skills.md`](references/skills.md#invocation).
- **By reader**: when part of the document runs in another agent. Give a worker's or reviewer's text its own block or file, such as `interrogation`'s `references/reviewer-prompt.md`, so the parent sends it whole and keeps its own steps out of the child's context.

## Leading words

A **leading word** is a compact concept the model already knows, which anchors a whole region of behaviour in one token: `grilling`'s _fog_ and _frontier_, `specs`' _lean_, `pr`'s _proof_, `delegate-subagents`' _settled_. Repeat the token, never the defining sentence, and it gathers meaning with each use. Reach for an existing word first. A coined word recruits no priors, so you pay in definition what a known word gives free.

It anchors twice. In the body, it steers execution: each appearance pulls the same behaviour, and inside a flat rule set it tells the agent what class of thing to look for. In a pointer, it steers invocation: when the same word lives in the user's prompts, the docs, and the code, the agent links them and reaches the material reliably. Glossary terms are the domain's leading words. Use the `GLOSSARY.md` term everywhere; each `_Avoid_` synonym splits the signal.

Hunt for passages that collapse into one word: a triad spelled out at three sites, or a sentence that gestures at one idea. "Its newest run is terminal and nothing is queued on its thread" became _settled_; "what the docs leave missing, vague, or contradictory" became _fog_.

**Positive phrasing.** A prohibition puts the banned behaviour in context and makes it more available. State the target instead: "Show the whole spec in your reply." A prohibition earns its place only as a guardrail you can't phrase positively, and then it follows the positive target: "Every PR goes through `pr`", then the commands it rules out.

**Hard rules.** Guardrails that hold in every phase go in a `## Hard rules` section near the top, each with its reason: "a `delegate_task` child inherits this thread's checkout, so T3 labels it with the wrong branch". The reason lets the agent extend the rule to cases you didn't list. Keep the list short, because every phase weighs every rule.

## Pruning

- **Single source of truth.** Give each meaning one home, so changing a behaviour is a one-place edit. Other documents point at the home: `swarm-tickets` owns the ticket workflow and defers every T3 mechanic to `delegate-subagents`. Duplication costs tokens and upkeep, and it inflates a meaning's rank past where it belongs.
- **The environment is a source of truth.** So are scripts, config, the directory layout, `--help` output, `docs/agents/*.md`, and the T3 tools: each tool's description and the live catalog from `orchestrator_capabilities`. A document that restates them is a **cache**, worth its load only when the lookup is expensive. Cache what the agent can't find by looking: the gotcha a tool's description doesn't confess ("`t3_thread_launch` doesn't check runtime modes"), the reason behind a choice, the repo's convention. Leave ids, model lists, and parameter shapes to the tools: "use catalog values only". A skill line saying `delegate_task` had no workspace parameter went stale when a T3 nightly added `isolation`.
- **Relevance.** Each line still bears on what the document does. A line goes stale when the behaviour or tool it describes changes, or it never bore on the task at all. Without pruning, the default fate is **sediment**: stale layers kept because adding feels safe and removing feels risky. Delete the old line in the same edit that changes the behaviour. The story of a run belongs in `references/example.md` as a **What went wrong** callout; the steps hold only the current behaviour.
- **No-ops.** A sentence the model already obeys by default pays load to say nothing. The test, "does it change behaviour against the default?", depends on the model, so settle a disagreement with a trial, not a debate. When a sentence fails, delete all of it rather than trimming words. A leading word too weak to beat the default is a no-op too; the fix is a stronger word ("relentless" for "thorough"), not a new technique.
