# Tickets: Post approved leave and reverse cancelled leave

Source: the spec for issue #174 (`174-post-approved-leave.md`). Stories (S1–S7) and
decisions (D1–D7) refer to that spec.

## Ticket rules

Each ticket becomes one PR, and each PR goes through interrogation. The tickets
are shaped so a reviewer can judge the PR against a single intent and find
fewer than five things to act on.

- **One intent.** The Intent paragraph is the PR description. Reviewers judge
  the code against it and don't question it.
- **Small.** Each PR stays inside one module, or makes one call across a module
  boundary. It is roughly 400 lines of production code or less.
- **No file crosses 1,000 lines.** Each new command gets its own
  `*.service.ts`, and each new rule its own domain service. If an existing
  file would cross 1,000 lines, split that file first as its own PR.
- **No speculative code.** Build only what this ticket's behaviour uses: no
  stubs, flags, or branches for later tickets.
- **Code in its own home.** Controllers only handle transport. Leave writes
  Attendance records only through Attendance's application service. Each
  apply case is its own handler, not another `if` in a shared flow.
- **Later work is named.** "Not in this PR" lists what a later ticket covers,
  so reviewers don't flag planned work as missing.
- **Proven at the boundary.** Atomicity, retries, races, and cross-Agency
  access are tested on real PostgreSQL. UI tickets include a browser test.

## Order

```text
Decisions   T1   T2   T3   T4            (run in parallel)

Posting     T5 Attendance input ─▶ T6 Post command ─▶ T7 Post UI
                         (T6 also waits on T1)

Cancel      T8 Request ─▶ T9 Decide ─▶ T10 Request/decide UI

Apply       T11 Apply: unposted ─▶ T12 Apply UI
            T13 Attendance replace input ─▶ T14 Apply: posted, open
            T15 Attendance locked request ─▶ T16 Apply: posted, locked ─▶ T17 Handoff UI
```

You can start T1–T5 and T8 today.

---

## T1 · Decide: leave without pay before Payroll, and the posting date

**Decision** (Triage + Research) · Resolves D1, D2 · Blocks T6

- **D1 (Triage):** Can a line of leave without pay be posted before Payroll
  exists in M4? Recommendation: no. Refuse it with a reason that names
  Payroll, and keep the application `APPROVED`.
- **D2 (Research):** Which effective date does a posting's ledger entry use:
  the first leave date, each covered date, or the posting date? Find the CSC
  or agency authority.

**Done when**
- [ ] Both answers are recorded with their authority or rationale.
- [ ] The docs match them.
- [ ] Anything that still has no authority is named as blocking, not guessed.

## T2 · Decide: kept quantity when line units differ from credit units

**Decision** (Research) · Resolves D3 · Blocks T14

Decide how the kept credit quantity is worked out from the kept dates when a
line is measured in working days, calendar days, or minutes.

**Done when**
- [ ] The rule is recorded with its authority, plus one worked example for a
      half day and one for leave split across policy versions.
- [ ] The docs match the rule, or the case is named as blocking.

## T3 · Decide: status after a partial cancellation, and who presses Apply

**Decision** (Grilling + Triage) · Resolves D4, D6 · Blocks T11

- **D4 (Grilling):** A partial cancellation currently leaves the application
  `CANCELLED`, so its kept days can never be posted. Options:
  - (a) return to the prior status;
  - (b) add a new status;
  - (c) require a new application.

  Recommendation: (a).
- **D6 (Triage):** Is a cancellation applied automatically on approval, or by
  a person? Recommendation: a person presses Apply.

**Done when**
- [ ] Both answers are recorded.
- [ ] The state table in the docs matches them.

## T4 · Decide: lines that span a lock boundary, and align the docs

**Decision** (Grilling + Triage) · Resolves D5, D7 · Blocks T15

- **D5 (Grilling):** A line falls partly in a locked Attendance period and
  partly in an open one. Options:
  - (a) treat it all as locked;
  - (b) split it;
  - (c) block it.

  Recommendation: (a).
- **D7 (Triage):** Make the schema and the ERD agree on the name of the
  locked-handoff effect, and on `leave_cancellations.leave_posting_id`.

**Done when**
- [ ] D5 is recorded with its rationale.
- [ ] The schema doc and the ERD agree on both D7 points.

---

## T5 · Attendance: accept a posted-leave input

**Build** · Attendance module only · Blocked by none · Supports S1

**Intent.** Give Attendance an application-service command that records an
immutable posted-leave input for an Employee's leave dates and recalculates
those Attendance Days. This is the only way Leave will reach Attendance. T6 is
its first caller.

**Acceptance**
- [ ] The command lives in its own service and runs inside the caller's
      transaction.
- [ ] It creates the input and recalculates only the affected open days.
- [ ] It refuses dates in a locked period, with a typed error.
- [ ] A repeated call with the same effect key returns the existing input and
      creates nothing new.
- [ ] Inputs from another Agency are rejected. Tests run on real PostgreSQL.

**Not in this PR:** replacing an input (T13); locked corrections (T15).

## T6 · Leave Posting command

**Build** · Leave module + one call to T5 · Blocked by T1, T5 · S1, S2

**Intent.** Add `POST /api/v1/leave-applications/:id/post`. It turns one
approved application version into a ledger debit for each account-charged
line, an Attendance input for each line, and consumed commitments, all in one
transaction or not at all.

**Acceptance**
- [ ] Only callers with `leave.applications.post` can post, and only from
      `APPROVED`. The controller only passes the request to
      `post-leave-application.service.ts`.
- [ ] Accounts are locked in a stable order. Certification, commitments, and
      balance are checked again after locking.
- [ ] Each line handles its own effects. A leave-without-pay line follows T1.
- [ ] One `leave_postings` row and its effect rows are written, the
      application becomes `POSTED`, and audit and outbox records are added.
- [ ] Any failure rolls back everything. A retry with the same idempotency key
      returns the first result, and a second posting of the same version is
      refused.
- [ ] Real-PostgreSQL tests cover the Attendance failure rollback, the retry,
      a race between two postings on one account, and cross-Agency access.

**Not in this PR:** the workspace button (T7).

## T7 · Post action in the Leave workspace

**Build** · Web only · Blocked by T6 · S1, S2

**Intent.** Let a Leave Administrator post an approved application from the
workspace and see the result or the reason it was refused.

**Acceptance**
- [ ] Post appears for `APPROVED` applications when the user has permission.
      The API still enforces it.
- [ ] The button can't double-submit. A refusal shows its reason; a failure
      can be retried.
- [ ] Loading, denied, and stale states are handled. A browser test covers
      the path from approval to posting.

## T8 · Request a Leave Cancellation

**Build** · Leave module · Blocked by none · S3

**Intent.** Add a command that records an Employee's cancellation request, or
a Leave Administrator's evidenced request, for approved or posted leave, and
moves the application to `CANCEL_REQUESTED`.

**Acceptance**
- [ ] It needs `leave.applications.request_cancel`, a reason, and evidence.
- [ ] Scope is checked by its own domain service: the whole leave, or dates on
      one line that include the line's first or last date. Dates outside the
      line, excess quantity, or a gap in the middle are refused.
- [ ] Only one cancellation can wait for a decision at a time, and this is
      enforced in the database.
- [ ] The record stores `prior_status`, decision `REQUESTED`, and effect
      `NOT_READY`. Real-PostgreSQL and cross-Agency tests are included.

**Not in this PR:** deciding (T9); the UI (T10).

## T9 · Approve and reject a Leave Cancellation

**Build** · Leave module · Blocked by T8 · S4

**Intent.** Add the approve and reject commands. A rejection restores the
exact prior status. An approval only marks the effect as ready to apply.

**Acceptance**
- [ ] Approve needs `leave.applications.cancel`, and reject needs
      `reject_cancel` plus a reason.
- [ ] Nobody can decide a cancellation they requested or recorded.
- [ ] A rejection restores `prior_status` and changes nothing else.
- [ ] An approval sets the effect to `PENDING`. No commitment, ledger, or
      Attendance row changes, and a test proves it.

**Not in this PR:** applying (T11).

## T10 · Request and decide cancellations in the workspace

**Build** · Web only · Blocked by T9 · S3, S4, S7

**Intent.** Let Employees request a cancellation and Approvers decide one,
with the request's dates and its decision visible.

**Acceptance**
- [ ] The date picker offers only valid scopes: whole, start, or end. The API
      stays authoritative.
- [ ] An approved cancellation reads "Approved, not yet applied".
- [ ] A browser test covers request, rejection, and approval.

## T11 · Apply a cancellation to approved, unposted leave

**Build** · Leave module · Blocked by T3, T9 · S5

**Intent.** Add the apply command and its first case: an approved cancellation
of unposted leave releases its commitments. A partial cancellation then
reserves only the kept amount.

**Acceptance**
- [ ] The apply service picks one handler per case. This PR adds only the
      unposted handler. Posted leave is refused with a typed, blocking reason
      until T14.
- [ ] A whole cancellation releases the commitment. A partial one releases it
      and adds a smaller linked successor in the same account.
- [ ] The application status follows T3.
- [ ] Effects run under a savepoint. On failure, only the `FAILED` record
      commits, the cancellation stays approved, and the reason is shown as
      retryable or blocking.
- [ ] A retry with the same key completes the cancellation, and credits are
      never released twice. Real-PostgreSQL tests are included.

**Not in this PR:** posted leave (T14, T16); the UI (T12).

## T12 · Apply action and effect status in the workspace

**Build** · Web only · Blocked by T10, T11 · S5, S7

**Intent.** Let a Leave Administrator apply an approved cancellation, and show
its effect as pending, applied, or failed with the reason.

**Acceptance**
- [ ] Apply follows T3, can't double-submit, and offers a retry only when the
      reason is retryable.
- [ ] A browser test covers applying a cancellation of unposted leave.

## T13 · Attendance: replace a posted-leave input in an open period

**Build** · Attendance module only · Blocked by T5 · Supports S5

**Intent.** Add an Attendance command that supersedes a posted-leave input
with a successor input covering only the kept dates. The successor's quantity
is zero when nothing is kept. The affected open days are then recalculated.

**Acceptance**
- [ ] The original input is never edited; the successor links to it.
- [ ] Locked dates are refused with the same typed error as in T5.
- [ ] Repeating the call with the same effect key creates nothing new.
      Real-PostgreSQL tests are included.

## T14 · Apply a cancellation to posted leave while Attendance is open

**Build** · Leave module + one call to T13 · Blocked by T2, T6, T11, T13 · S5

**Intent.** Add the posted-leave handler. Each cancelled ledger debit gets an
exact linked reversal, and a partial cancellation re-posts the kept part on
the original date. Attendance then replaces the input.

**Acceptance**
- [ ] It is a new handler beside the unposted one. The shared apply flow gains
      no branches.
- [ ] The kept quantity follows T2.
- [ ] A balance read "as of" a time before the cancellation still shows the
      original posting.
- [ ] If Attendance refuses because a date is locked, the command fails as a
      blocking error and the posting stays in force.
- [ ] Whole and partial cancellations are tested on real PostgreSQL.

**Not in this PR:** locked Attendance (T16).

## T15 · Attendance: accept a locked posted-leave correction from Leave

**Build** · Attendance module only · Blocked by T4, T5 · Supports S6

**Intent.** Add an Attendance command that records a `POSTED_LEAVE_INPUT`
correction for locked dates at `FOR_AUTHORIZATION`, referencing the Leave
Cancellation. The existing Locked Attendance Adjustment flow completes it.

**Acceptance**
- [ ] Locked days, DTRs, and payroll publications are never edited.
- [ ] The cancellation's requester and approver can't authorize the
      correction.
- [ ] A missing authorization route is refused with a typed reason, and the
      call can be retried by effect key. Real-PostgreSQL tests are included.

## T16 · Apply a cancellation to posted leave in locked Attendance

**Build** · Leave module + one call to T15 · Blocked by T14, T15 · S5, S6

**Intent.** When the cancelled dates are locked, the posted-leave handler hands
them to Attendance as a correction awaiting authorization instead of
replacing the input. Lines that span a lock boundary follow T4.

**Acceptance**
- [ ] The ledger reversal and replacement still match T14.
- [ ] Choosing between "replace" and "request correction" is one small rule,
      with tests at the lock boundary.
- [ ] A refusal from Attendance records `LEAVE_CANCELLATION_ATTENDANCE_REFUSED`
      as blocking, and a retry completes the cancellation once the route
      exists.

## T17 · Show the Attendance handoff in the workspace

**Build** · Web only · Blocked by T12, T16 · S6, S7

**Intent.** Show a cancellation of locked leave as "Awaiting Attendance
authorization" or "Blocked: reason", and never as complete before Attendance
finishes.

**Acceptance**
- [ ] The status comes from Attendance's own status, not from Leave's.
- [ ] A browser test covers the pending state and the authorized state.

---

## Coverage check

| Spec item                      | Tickets         |
| ------------------------------ | --------------- |
| S1, S2 Post safely             | T5, T6, T7      |
| S3, S4 Request and decide      | T8, T9, T10     |
| S5 Apply and return credits    | T11–T14, T16    |
| S6 Locked authorization        | T15, T16        |
| S7 Show what's pending         | T10, T12, T17   |
| D1–D7                          | T1–T4           |
| Payroll                        | none (M4)       |
