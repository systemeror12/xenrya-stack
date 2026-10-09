# Issue tracker: local markdown

Issues, specs, and tickets for this repo live as markdown files under
`.scratch/`.

## Layout

- One directory per issue: `.scratch/<NNN>-<slug>/`, numbered from `001`.
- The issue itself is `issue.md` in that directory.
- Its spec is `spec.md`, and its tickets are `tickets/<NN>-<slug>.md`, one
  file per ticket.

Each issue and ticket file opens with these lines:

```markdown
Status: <triage label from triage-labels.md, or closed>
Assignee: <name, or blank>
Blocked by: <ticket numbers, or blank>
```

## Operations

- **Read**: read the file at the path or number the user gives.
- **List**: scan `.scratch/*/issue.md` and `.scratch/*/tickets/*.md` for
  their `Status:` lines.
- **Create**: make the next numbered directory and its `issue.md`.
- **Blocked by**: list the blocking ticket numbers in `Blocked by:`. A ticket
  is unblocked when every ticket it lists is closed.
- **Claim**: fill in `Assignee:` and save before any other work. A file with
  an assignee is claimed.
- **Comment**: append to a `## Comments` section at the end of the file.
- **Label**: set `Status:` to the role's label.
- **Close**: set `Status: closed`, with a closing comment.

## Skill actions

- **Publish a spec** (`specs`): write it as `spec.md` in the issue's directory.
- **Publish tickets** (`to-tickets`): write each ticket under `tickets/`.
- **Claim a ticket** (`swarm-tickets`): fill in its `Assignee:`, as in Claim.
