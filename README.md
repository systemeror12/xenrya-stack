# xenrya-stack

Agent skills for Claude Code and Codex, run inside [T3 Code](https://github.com/pingdotgg/t3code). Together they take work from an issue to a reviewed pull request.

```text
grilling / domain-modeling → specs → to-tickets → swarm-tickets (implement → pr) → interrogation → swarm-tickets revise
```

| Skill | Invoked by | Does |
| --- | --- | --- |
| `setup-xenrya-stack` | model | Writes the per-repo `docs/agents/` files the other skills read. Run it once per repo. |
| `grilling` | user | Interviews you until the plan has no fog left. |
| `domain-modeling` | model | Keeps `GLOSSARY.md` and ADRs current as terms settle. |
| `specs` | user | Builds a one-page spec from the source-of-truth docs. |
| `to-tickets` | user | Breaks a spec into tickets, one PR each. |
| `prototype` | user | Builds three or more switchable UI variants. |
| `implement` | model | Builds one ticket, tests it, and opens a PR. |
| `tdd` | model | Proves a bug with a failing test before the fix. |
| `pr` | model | Writes a PR description backed by the diff, images, and checks. |
| `interrogation` | user | Several models review a change; a lead judges the findings. |
| `delegate-subagents` | model | Runs scoped work on a chosen harness, model, and effort through T3. |
| `swarm-tickets` | user | Claims tickets and implements each in its own T3 worker thread. |
| `t3-guided-video` | user | Records readable walkthrough videos in T3's browser. |
| `writing-for-agents` | model | Writes skills, briefs, and instruction files. |

User-invoked skills start with `/name` in Claude Code or `$name` in Codex.

## Install

Symlink each skill directory into every harness's skills directory, as [`writing-for-agents`](skills/productivity/writing-for-agents/references/skills.md#where-a-skill-lives) describes.
