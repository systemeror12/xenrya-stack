---
name: setup-xenrya-stack
description: "Repo setup for the xenrya-stack skills: issue tracker, triage labels, and domain docs. Use when a repo has no docs/agents/issue-tracker.md, or to switch issue trackers."
---

# Setup Xenrya Stack

Write the per-repo configuration the xenrya-stack skills read: where issues
live, which labels mark triage state, and where the domain docs live. Each
answer becomes a file in `docs/agents/`. An **Agent skills block** in the
repo's instructions file (`AGENTS.md` or `CLAUDE.md`) points to those files.

## Steps

1. **Explore.** Read the repo before asking anything:
   - `git remote -v`: the host, and `owner/repo` on GitHub;
   - `AGENTS.md` and `CLAUDE.md` at the root: which exist, whether one imports
     the other (an `@AGENTS.md` line), and whether either already has an
     `## Agent skills` block;
   - `docs/agents/`: files from an earlier run;
   - `GLOSSARY.md`, `GLOSSARY-MAP.md`, `docs/adr/`, and `src/*/docs/adr/`;
   - `.scratch/`: a local issue convention already in use;
   - monorepo signals: `pnpm-workspace.yaml`, a `workspaces` field in
     `package.json`, or `packages/*` with their own sources;
   - on GitHub, the existing labels: `gh label list --limit 200`.

   Done when every item has a finding, "absent" included.
2. **Ask.** Summarise the findings in a few lines. Then ask the questions
   below one at a time, and wait for each answer. Open each question with your
   recommendation so the user can accept it in a word. When an earlier run's
   file exists, recommend keeping what it says.
   - **Issue tracker.** Recommend GitHub when a remote points at github.com,
     and local markdown when there is no remote. The options:
     - GitHub, through `gh`;
     - local markdown under `.scratch/`;
     - other (GitLab, Jira, Linear). The user describes in one paragraph how
       to read, create, claim, comment on, and close an issue.
   - **Triage labels.** Recommend the defaults in
     [`references/triage-labels.md`](references/triage-labels.md). When the
     tracker already has a label for a role (say `bug:triage` for
     `needs-triage`), recommend mapping the role to it. Record every override.
   - **Domain docs.** Recommend single-context: one `GLOSSARY.md` and
     `docs/adr/` at the root. When exploration found monorepo signals or a
     `GLOSSARY-MAP.md`, recommend multi-context, and ask which directories are
     contexts.
   - **Instructions file.** Ask only when neither `AGENTS.md` nor `CLAUDE.md`
     exists, or when both exist and neither imports the other. When neither
     exists, ask which one to create: `AGENTS.md` (read by Codex and most
     other agents) or `CLAUDE.md` (read by Claude Code). The user picks;
     offer no recommendation. When both exist, ask which one to edit.

   Done when every question asked has the user's answer, and one instructions
   file is chosen. With exactly one file present, that file is chosen. With
   both present and one importing the other, the imported file is chosen.
3. **Draft.** Before writing anything, show the user:
   - each `docs/agents/` file, filled from its [seed template](#seed-templates)
     with their answers;
   - the [Agent skills block](#agent-skills-block), and the file it goes in;
   - on GitHub, each label the mapping names that the tracker lacks, which
     `gh label create` will add.

   Apply their edits. Done when the user approves the draft.
4. **Write.** Write the approved draft:
   - `docs/agents/issue-tracker.md`. For an other tracker, write it from the
     user's paragraph under the GitHub template's headings.
   - `docs/agents/triage-labels.md`.
   - `docs/agents/domain.md`, keeping only the chosen layout's section.
   - The Agent skills block. Replace an existing `## Agent skills` block in
     place, and leave the rest of the file untouched. A newly created file
     holds only the block.
   - On GitHub, run `gh label create` for each approved label.

   Done when every drafted file is on disk, and each label was created or its
   error is in the report.
5. **Report.** List the files written, the labels created, and the three
   choices. Tell the user they can edit `docs/agents/*.md` directly, and rerun
   this skill to switch trackers.

## Agent skills block

```markdown
## Agent skills

### Issue tracker

<One line: where issues live.> See `docs/agents/issue-tracker.md`.

### Triage labels

<One line: the default labels, or which roles are remapped.> See `docs/agents/triage-labels.md`.

### Domain docs

<One line: single-context or multi-context, and where `GLOSSARY.md` lives.> See `docs/agents/domain.md`.
```

## Seed templates

| Output file | Template |
| --- | --- |
| `docs/agents/issue-tracker.md` | [`issue-tracker-github.md`](references/issue-tracker-github.md) or [`issue-tracker-local.md`](references/issue-tracker-local.md) |
| `docs/agents/triage-labels.md` | [`triage-labels.md`](references/triage-labels.md) |
| `docs/agents/domain.md` | [`domain.md`](references/domain.md) |
