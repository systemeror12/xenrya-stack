# Example: three tickets, a worktree per ticket

This batch ran in the `lingkod-hr` repository. The parent was Claude Opus 5.5 and the workers were Claude Opus 5.5 · Medium. It shows every phase, then one review and one correction round. The turn boundaries are marked, because they are where the workflow most often goes wrong.

## Turn 1: the request

```text
$swarm-tickets Use Opus 5.5 medium
https://github.com/systemeror12/lingkod-hr/issues/464
https://github.com/systemeror12/lingkod-hr/issues/465
https://github.com/systemeror12/lingkod-hr/issues/466

each tickets have its own worktree origin/dev
```

**Preflight.** The parent invoked `delegate-subagents`, loaded the T3 schemas, read the three issues and the ticket rules they link to, and read `AGENTS.md`, which names `scripts/setup-worktree.sh`. Selection: `claudeAgent · claude-opus-5-5 · effort=medium · full-access`. Base: `origin/dev` at `0f68ea9`. Baseline: `format:check` already failed on `mandatory-leave-evaluator.ts`.

**Claim.** It assigned #464, #465, and #466 to the user on GitHub, which is the tracker's claim convention.

**Plan waves.** "Each ticket has its own worktree" selects a worktree per ticket. The parent followed the repository's existing worktree layout:

```bash
git fetch origin dev
for i in 464 465 466; do
  git worktree add -b t3code/implement-issue-$i ~/.t3/worktrees/lingkod-hr/swarm-issue-$i origin/dev
done
# One at a time: each run claims a database and E2E ports.
for i in 464 465 466; do
  (cd ~/.t3/worktrees/lingkod-hr/swarm-issue-$i && bash scripts/setup-worktree.sh)
done
```

Each worktree got its own database (`hris_swarm_issue_<N>`) and ports. The tickets don't depend on each other, so all three went in wave 1. Two of them were likely to add a migration.

> **What went wrong:** no migration numbers were reserved, and all three workers took `0120`. At delivery the parent had to rename two migration directories and fix `_prisma_migrations` in two worktree databases. Reserving `0120`, `0121`, and `0122` in the briefs avoids that.

**Dispatch.** Three `delegate_task` calls in one message, not `t3_thread_launch`:

```json
{
  "title": "#464: Set authTime at TOTP confirmation in forced enrollment",
  "role": "implementation",
  "mode": "async",
  "target": {"providerInstanceId": "claudeAgent", "model": "claude-opus-5-5", "options": {"effort": "medium"}},
  "runtimeMode": "full-access",
  "clientRequestId": "swarm-20261009-a-464-a1",
  "task": "Read the skill at /home/xenrya/.claude/skills/implement/SKILL.md and follow it for this ticket. ..."
}
```

The Workspace field of that brief:

```text
Workspace: /home/xenrya/.t3/worktrees/lingkod-hr/swarm-issue-464 on branch
`t3code/implement-issue-464`, created from origin/dev (0f68ea9). Your shell may
start in /home/xenrya/Desktop/lingkod-hr — that is the developer's main
checkout; do NOT edit or run commands there. Run every command with that
worktree as the working directory and use absolute paths inside it. The
worktree's setup gate already passed (`Worktree ready`, own database
hris_swarm_issue_464, E2E ports web 28530 / API 28531). Node via
`fnm exec --using .node-version` if `node` isn't on PATH.
```

**End of turn 1.** The parent reported the selection line, the three worktrees, and the ticket → `taskId` table, then ended the turn. It did not sleep or poll.

## Turns 2–4: completion notifications

Each `Delegated task "#464: …" finished` notification started a turn. The parent called `task_status` once, read the diff in that worktree, and checked each acceptance criterion. One example: #465 added a migration because `security_events` has forced row-level security, and the parent compared it with the precedent in migration `0115`. Then it recorded the ticket as accepted. While other workers were still running, it ended the turn with the updated table.

> **What went wrong:** all three workers ran the full database suite at the same time. One run crashed on an unrelated file, and `fnm` raced on a shared symlink. The Validation field should leave the full and database suites to the parent.

## Turn 4, continued: deliver

Accepting #466, the last ticket, started delivery in the same turn:

1. **Integrate.** It renumbered the migrations to `0120`, `0121`, and `0122` in the order the PRs would merge.
2. **Validate.** It ran typecheck, lint, unit tests, and the API database suite in each worktree in turn, through a background Bash run, while it loaded `pr`.
3. **Commit and push.** One commit per worktree, then a push of each branch.
4. **`pr` for each PR.** It invoked `pr` with the base `dev`, each head branch, `Closes #<N>`, and the validation it had already run. That opened PRs #494 (#465), #495 (#464), and #496 (#466).
5. **Link.** `link_pull_request` for each PR, then `list_thread_pull_requests`.
6. **Final report.** It gave the merge order, noted that `Closes #N` won't close the issues because `dev` isn't the default branch, and named the baseline `format:check` failure.

## Review: interrogation

```text
$interrogation to 3 PRs
$delegate-subagents use GPT 6.1 Sol High as subagents
```

The parent froze each PR's diff (`git diff 0f68ea9...HEAD > /tmp/interrogation/pr-<N>.diff`). It then dispatched one reviewer per PR with `delegate_task` and `role: "review"`, with a `clientRequestId` such as `interrogate-20261009-pr495-gpt61sol-r1`, and ended the turn. When the reviews came back, it gave a verdict per PR: Act On, Consider, Noted, Dismissed.

## Revise: a correction round

```text
fix the issue by assigning the finds to its respective previous subagents
```

"Previous subagents" means each ticket's original worker selection, run as a new `delegate_task` round in the same worktree. It does not mean the reviewers, and it does not mean messaging the old threads. Each brief kept the original fields and added:

```text
This is round 2 (correction) for ticket #464. You implemented it in round 1;
the work is committed at 441d2b8 on branch `t3code/implement-issue-464` and
open as PR https://github.com/systemeror12/lingkod-hr/pull/495 (base `dev`).
An adversarial review followed and the lead reviewer accepted ONE finding to
fix. Fix only that.
- <location, problem, the expected fix, the test that proves it>
Do NOT change: <dismissed findings and why>
```

The `clientRequestId`s were `swarm-20261009-a-<ticket>-a2`. All three round-2 workers hit a rate limit and failed, but their test runs kept going in the worktrees. The parent waited for those processes with a background Bash `until` loop rather than starting new workers, then inspected the worktrees and finished the validation itself, one worktree at a time.

> **What went wrong:** the parent pushed the fixes and then wrote the new PR bodies by hand with `gh pr edit`, judging `pr` too heavy for a small change. Hard rule 3 says every update goes through `pr`, whatever its size.

## Base-branch update

PR #496 later conflicted with `dev`. The branch history showed that the repository merges `origin/dev` into feature branches rather than rebasing, so the parent did that in the #466 worktree. It resolved the conflict, applied the new migrations to that worktree's database, validated, and pushed. Under phase 7, it should then have run `pr` for #496 again.
