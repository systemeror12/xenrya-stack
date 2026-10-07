# T3 framing pattern

Use the helper for guided recordings when scrolling and highlighting make a flow easier to follow. It changes temporary page presentation and leaves application values alone.

## Install and frame

Read `../scripts/frame_page.js` relative to this reference. Trim leading and trailing whitespace from its contents, then pass the result as `preview_evaluate.expression`, with the selected `tabId`. T3 requires a nonempty expression without surrounding whitespace. Reinstall after a document navigation; the previous page's helper will no longer exist.

The helper uses DOM CSS selectors. Snapshot `aria-ref` values and Playwright role/text locators belong to T3 interaction tools and cannot be passed to `document.querySelectorAll`. Choose a stable CSS selector that uniquely identifies the visible control. If a selector is ambiguous, inspect the page and narrow it rather than framing an arbitrary match. For controls inside an iframe that the main-frame evaluator cannot access, use the snapshot's frame-aware locator and focused scrolling; verify framing with a screenshot.

Example `preview_evaluate.expression`, with `awaitPromise=true`:

```js
window.__t3GuidedVideo.frame('input[name="email"]', {
  frameSelector: '[data-testid="email-field"]',
  holdMs: 500
})
```

`frameSelector` is optional. Use it when the control's label or row should remain visible; it must contain the exact target. The returned `fullyInViewport` is a diagnostic. A target near the document edge or behind a sticky header still needs visual inspection, and may require a different scroll position.

Now edit that same control with `preview_type`, `preview_click`, or another focused T3 tool using its semantic locator. Re-read the snapshot when references become stale. A snapshot taken after framing supplies fresh references before interaction.

Wait for the expected app state, then hold the displayed value with another evaluated expression and `awaitPromise=true`:

```js
window.__t3GuidedVideo.hold(750)
```

Reading holds are for the viewer. Use `preview_wait_for` or an app-state check to establish readiness before the hold.

For autocomplete, frame the input before typing and again after selecting its visible option. For table edits, frame the active cell, scroll horizontally when necessary, and frame the completed row afterward. In dialogs, keep both the field labels and final action visible. Avoid overlays that cover the values being taught.

## Stop and clear

Hold the final state, stop recording, then remove the helper:

```js
window.__t3GuidedVideo?.clear()
```

On an aborted flow, stop the active recording when possible and clear the helper in cleanup. Keep the recording path returned by T3; capture errors do not make an incomplete flow successful.

## Inspect artifacts

Use `preview_snapshot({tabId,save:true})` for saved screenshots needed as separate evidence. Video readability must also be assessed from the recorded file.

The packaging helper emits numbered PNG samples and a contact sheet for each flow. Inspect enough to cover initial entry, below-fold fields, horizontal table scrolling, dialogs, and final state. Sample additional timestamps from the individual MP4 when a short action is missed by the contact sheet. Adjust framing or pacing and re-record only the affected flow, respecting any data side effects.
