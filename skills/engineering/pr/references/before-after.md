# Capturing before and after images

Capture the same screen in the same state at the **base** commit and the
**head** commit, so a reviewer compares like with like.

1. **Worktrees.** Create two throwaway detached worktrees, one at base and one
   at head. Use paths that you own, outside the user's checkouts. Run the
   repository's own worktree setup so each one gets its own database and
   ports. Done when both worktrees build and start.
2. **Driver.** Pick the existing browser test that walks through the changed
   screen. Add a `page.screenshot` step at each moment that shows the
   difference, writing to a folder outside both worktrees. If no test reaches
   the screen, drive the running app directly with a browser tool. Done when
   each changed screen has a capture point at base and at head.
3. **Run.** Run the driver at base and then at head. Run them one after the
   other, because the two worktrees share infrastructure. Done when every image
   exists.
4. **Inspect.** Open every image. Check that each pair shows the same screen,
   the same record, and the change the Summary describes. Re-capture any pair
   that differs only by noise such as an ID or a time. Done when every pair
   proves its claim.
5. **Clean up.** Remove both worktrees and drop their databases. Keep the
   images. Done when the user's worktree list looks as it did before.

The screenshot steps stay in the throwaway worktrees and never reach the PR.
The Validation section says they were added temporarily.
