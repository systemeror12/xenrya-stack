# Skills

The skill branch of [`writing-for-agents`](../SKILL.md): where a skill lives, its frontmatter, how it is invoked, how skills point at each other, and the conventions the stack's skills share. The writing itself follows `SKILL.md`.

## Where a skill lives

A skill is a directory, `skills/<group>/<name>/`.

- **Groups.** `engineering` holds the spec-to-PR work, `orchestration` holds T3 parents and their workers, and `productivity` holds the rest.
- **Contents.** `SKILL.md` and `agents/openai.yaml`; `references/` for disclosed reference, such as templates, variants, and the worked example; `scripts/` for code the skill runs, resolved relative to `SKILL.md`.
- **Install.** Each skill is a symlink to its directory in the main checkout, from `skills/<name>` in every Claude Code config directory (`~/.claude`, `~/.claude-work`) and from `~/.agents/skills/<name>`. Add every link for a new skill, and remove them all for a deleted one. An edit made in another worktree isn't installed until it reaches the main checkout, so trial it by absolute path.

## Frontmatter

```yaml
---
name: <directory name>
description: "Use for \"<phrase>\", \"<phrase>\", or \"<phrase>\". <One sentence on what the skill does or produces.>"
disable-model-invocation: true # user-invoked skills only
---
```

The description is the skill's top-level pointer, so the pointer rules in `SKILL.md` apply in full: the quoted phrases first, one per branch or per phrase the user actually types, then one sentence. A skill adapted from another project records its source under `metadata`, as `interrogation` does.

## Invocation

The choice trades the two loads:

- **Model-invoked.** Omit `disable-model-invocation`, and set `allow_implicit_invocation: true`. The description sits in every session's context, so the agent can fire the skill unprompted and other skills can invoke it. Pick it when the agent must reach the skill on its own (`tdd` on "fix this bug"), or another skill invokes it (`pr` from `swarm-tickets`). A model-invoked skill is also the home for reference several skills share: `grilling` keeps `domain-modeling` running for its whole session.
- **User-invoked.** Set `disable-model-invocation: true` and `allow_implicit_invocation: false`. Zero context load: only the human starts it, with `/name` in Claude Code or `$name` in Codex. Pick it for work a human should start on purpose, such as claiming tickets or a multi-model review. Its description still shows in the human's skill menu, so write it in the same form.

Pick model-invocation only when the agent or another skill must reach the skill. `disable-model-invocation` is Claude Code's switch and `allow_implicit_invocation` is Codex's, so set both. They may differ on purpose, as in `implement`.

No skill can fire a user-invoked skill, so another skill reaches one by its file path: `to-tickets` links `../interrogation/SKILL.md` to read its review bar.

**Split by invocation** when a trigger the user really types should reach part of a skill on its own, or another skill must reach that part. The new description costs context load on every turn, so the independent reach has to be worth it.

## Pointers between skills

- **Name the skill, then give a fallback path.** "Invoke `delegate-subagents`. If your catalog doesn't have it, read this repo's copy at `../delegate-subagents/SKILL.md`." The name works through either harness's catalog; the path works when the catalog lacks the skill.
- **Link the section when only part applies:** `../delegate-subagents/SKILL.md#2-resolve-the-target`. Other skills link headings by anchor, so search the repo for a heading's anchor before you rename the heading.
- **Own your workflow; defer the mechanics.** A skill owns its domain and points at the skill that owns each mechanic it uses. Say so near the top, as `swarm-tickets` does: "All T3 Code orchestration … lives in `delegate-subagents`".
- **A brief uses an absolute path.** A worker can't count on either harness's skill syntax: "Read the skill at <absolute path to implement/SKILL.md> and follow it."

## Body conventions

- **Opening.** `# <Title>`, then one paragraph that names the deliverable and bolds the skill's leading words where it defines them.
- **Steps.** Numbered, each opening with a bold verb (**Gather.**, **Write.**) and ending on a `Done when` line. A skill with phases lists them in order up front: "**preflight → claim → plan waves → …**".
- **Hard rules** near the top, for guardrails that hold in every phase, each with its reason.
- **Tables** for mappings: a section to its contents, the user's wording to a tool field, a harness to its mechanics.
- **Output in the thread.** A deliverable the user reads, such as a spec, a ticket set, or a PR description, goes in the reply rather than a scratch file, unless the user asks for a file.
- **Final report.** The last step says what the reply contains, including skipped checks and work still running.
- **Worked example.** `references/example.md` walks through one real run. When a run goes wrong, fix the step, then add a **What went wrong** callout at the point in the example where it happened.

## Harness notes

Skills run on Claude Code and Codex. Write T3 tools by bare name, such as `delegate_task`, and give the harness mapping for the mechanics the skill uses, taking the rows from `delegate-subagents`' [Harness notes](../../../orchestration/delegate-subagents/SKILL.md#harness-notes). In the step that first needs deferred T3 tools in Claude Code, give one ToolSearch `select:` line naming every tool the skill will call, so a Medium-effort run loads them in a single call.

## agents/openai.yaml

```yaml
interface:
  display_name: "<Title Case name>"
  short_description: "<what it does, in about 50 characters>"
  default_prompt: "Use $<name> to <the outcome and its key requirement>."

policy:
  allow_implicit_invocation: <true | false>

dependencies: # only when the skill can't run without T3
  tools:
    - type: "mcp"
      value: "t3-code"
      description: "<what the skill uses T3 for>"
```
