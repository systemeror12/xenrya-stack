# Writing a release PR

A release PR promotes work that was already reviewed from an integration
branch to a release branch, such as `dev` → `version-4`. Its body is release
notes for users. It doesn't describe the merge itself. On GitLab, PRs are
merge requests (MRs): use `glab` where these steps show `gh`.

1. **List the merges.** Fetch both branches, then run
   `git log --first-parent --oneline origin/<target>..origin/<source>`. Skip
   back-merges of the target into the source. Done when every remaining
   commit is a merge or squash of one reviewed PR.
2. **Map to PRs.** Read each PR number from its commit message:
   - GitLab merge commit: `See merge request <group>/<project>!N`.
   - GitHub merge commit: `Merge pull request #N from …`.
   - Squash commit: `(#N)` or `(!N)` at the end of the subject.

   If the message has no number, look it up by branch with
   `gh pr list --head <branch> --state merged` or
   `glab mr list --source-branch <branch> --merged`. Done when every commit
   has a PR URL.
3. **Read each PR.** Read each PR's title and Summary with
   `gh pr view N --json title,body,url` or `glab mr view N`. The commit
   subject alone is not enough. Sort the PR by its conventional-commit type:
   `feat` goes under features, and `fix` or `perf` goes under fixes. Leave out
   `chore`, `ci`, `docs`, `test`, and `refactor` PRs that users won't notice.
   Done when every PR is sorted or marked as left out.
4. **Check the merge.** Run
   `git merge-tree --write-tree origin/<target> origin/<source>`. A non-zero
   exit means conflicts: stop and report them to the user. Done when the merge
   is clean. The check goes in the report to the user, not in the body.
5. **Title.** Write `release(<target>): <what ships>`. The description lists
   the main changes as short lower-case noun phrases, joined by commas and a
   final "and". Done when the title fits on one line.
6. **Write.** Draft the body from the format below. Done when every sorted PR
   is linked from a bullet.

## Format

- Use two sections: **Notable features added** and **Notable fixes**. Leave
  out a section with no bullets.
- Start each bullet with a bold label for the area, then write one or two
  sentences on what users can now do, or what was broken and now works.
  Leave out file names, selectors, migrations, and other details of the
  implementation.
- End each bullet with links to its source PRs. Use `[Details](<url>)` for a
  single PR. When one bullet groups several PRs, give each link a short name,
  such as `[Pages](<url1>), [Header](<url2>)`.
- Put related small fixes, such as two PRs on the mobile layout, in one
  bullet.
- Leave out every section from the main skill except Attribution. Leave out
  the merge check and any text about merging the source into the target.

## Example

From [prince-hris !275](https://gitlab.com/live_nb/prince-hris/-/merge_requests/275),
`dev` → `version-4`:

**Title:** `release(version-4): membership review retries, Philippine addresses, cart cleanup, and mobile layout`

```markdown
**Notable features added**

- **Request another Membership Review:** a rejected holder can use the new "Request Another Review" button to reopen the review form with the rejected request's details filled in. If they resubmit the same details, the form asks them to change at least one. [Details](https://gitlab.com/live_nb/prince-hris/-/merge_requests/274)

**Notable fixes**

- **Membership Review Requests:** Automatic Reason now shows readable labels, such as "No matching Member Record", in the list, the form, and the group-by. [Details](https://gitlab.com/live_nb/prince-hris/-/merge_requests/273)
- **Philippine addresses:** addresses print the province name ("Bangued Abra 2800") instead of the PSGC code. [Details](https://gitlab.com/live_nb/prince-hris/-/merge_requests/272)
- **Cart and checkout:** removed the "I have a promo code" link and the duplicate checkout button, so "Process Checkout" is the only one left. [Details](https://gitlab.com/live_nb/prince-hris/-/merge_requests/271)
- **Mobile layout:** the homepage and event register pages fit on phones, the hamburger menu no longer repeats the logo, and the header logo is smaller. [Pages](https://gitlab.com/live_nb/prince-hris/-/merge_requests/269), [Header](https://gitlab.com/live_nb/prince-hris/-/merge_requests/270)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
