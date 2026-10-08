# Post approved leave and reverse cancelled leave

Issue #174 · M3

## Problem

Approving leave changes nothing. The Employee's credits are not deducted,
Attendance still marks them absent, and the reserved credits are never used up.
There is also no way to undo approved or posted leave without editing history.

## Why

When the balance, the Attendance Days, and the leave status disagree, HR stops
trusting all three. Government leave records are audited, so every change has
to be traceable to its original fact.

## Scope

- Post an approved application: debit the ledger, give Attendance its leave
  input, and use up the reserved credits, all together or not at all.
- Request, approve, or reject a cancellation of all of the leave or the start
  or end of it.
- Apply an approved cancellation to leave that is:
  - approved but unposted;
  - posted, with its Attendance still open;
  - posted, with its Attendance locked.
- Leave workspace actions and status for all of the above.

## Out of scope

- Payroll effects, including leave without pay deductions. These move to M4.
- Withdrawing leave before approval. That flow already exists.
- Mandatory-leave cancellation by the agency head for exigency.

## Actors

| Who                          | Does                                                                  |
| ---------------------------- | --------------------------------------------------------------------- |
| Employee                     | Requests a cancellation                                               |
| Leave Administrator          | Posts leave, records evidenced requests, applies cancellations        |
| Approver                     | Approves or rejects a cancellation, and never their own               |
| HR Administrator (different person) | Authorizes Attendance corrections in locked periods            |

## User stories

1. As a Leave Administrator, I post approved leave, and credits, Attendance,
   and status update together.
2. As a Leave Administrator, I can retry a post safely without double-charging
   anyone.
3. As an Employee, I ask to cancel all of my leave or its first or last days,
   and I give a reason and evidence.
4. As an Approver, I decide the cancellation, and a rejection restores
   everything exactly.
5. As a Leave Administrator, I apply the cancellation, and credits return while
   Attendance is corrected.
6. As an HR Administrator, I authorize or block a locked Attendance correction,
   but I can't change the Leave decision.
7. As anyone, I can see what is finished and what still waits on Attendance.

## Rules that matter

**Posting**
- Leave can be posted only from `APPROVED`, and only once per approved version.
- Certification, commitments, and balance are all checked again at posting
  time. If any of them changed, posting is refused.
- Each account-charged line creates one ledger debit. Every line creates one
  Attendance input.
- Any failure rolls back everything, and the application stays `APPROVED`.
- Notifications are sent after commit. If they fail, the posting is not undone.

**Cancellation**
- A cancellation is its own record, with a reason, evidence, and an approval
  route.
- A partial cancellation must include the line's first or last date. A gap in
  the middle is rejected.
- Approving a cancellation changes nothing; only *applying* it does.
- For unposted leave, applying releases the reserved credits, or shrinks them
  for a partial cancellation.
- For posted leave, the original entry gets an exact reversal. A partial
  cancellation also re-posts the kept part on the original date.
- Open Attendance is corrected and recalculated. Locked Attendance gets a
  correction that waits for a different HR Administrator, and Leave never
  edits locked records.
- If applying fails, the cancellation stays approved, the original leave stays
  in force, and the reason is shown as retryable or blocking.

## What success looks like

- The balance, Attendance Days, and leave status never disagree.
- The ledger can be read "as of" any past moment, so originals are never lost.
- Retrying any command never creates duplicates.
- Nothing reads as complete while locked Attendance is still pending.
- An Agency never sees or touches another Agency's records.

## Decisions needed before building

| #   | Decision                                                                                   | Resolve by      | Recommendation                                     |
| --- | ------------------------------------------------------------------------------------------ | --------------- | -------------------------------------------------- |
| D1  | Can leave without pay be posted before Payroll exists?                                     | Triage          | No. Block it with a message naming Payroll.         |
| D2  | Which effective date does a posting's ledger entry use?                                     | Research (CSC)  | none until authority is found                      |
| D3  | How is the kept credit quantity worked out when line units ≠ credit units (half days, policy splits)? | Research | none until authority is found                  |
| D4  | After a partial cancellation, the status reads `CANCELLED` and the kept days can never be posted. Is that intended? | Grilling | Return to the prior status for partial cancellations |
| D5  | A line spans both locked and open Attendance. Split it, treat it all as locked, or block it? | Grilling       | Treat it all as locked; simpler and still truthful |
| D6  | Does the system apply a cancellation on approval, or does a person press Apply?             | Triage          | A person presses Apply                             |
| D7  | The docs disagree on the locked-handoff effect name and on `leave_cancellations.leave_posting_id` | Triage (doc fix) | Align the schema and ERD before building     |
