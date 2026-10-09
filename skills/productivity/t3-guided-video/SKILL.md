---
name: t3-guided-video
description: "Record readable T3 browser walkthroughs with guided scrolling, highlighting, pacing, packaging, and visual verification."
disable-model-invocation: true
---

# Guided T3 browser video

Produce a walkthrough a person can follow. Frame each important action by bringing its target into view, marking it, and holding the resulting state long enough to read.

## Prepare the walkthrough

Read the relevant repository instructions and identify the requested flows, app URL or development-server port, authentication, data mutations, expected results, and artifact destination. Use app startup scripts when a local server is needed. Keep existing business checks as acceptance criteria.

Map each flow into visible sections, including fields below the fold, table edits, autocomplete selections, dialogs, submission, and the resulting state. Choose a readable viewport; use 1440 by 900 CSS pixels when the application and user have no stronger requirement.

Preparation is complete when each requested flow has an action sequence, an expected outcome, and a recording label. Collect any missing authorization before a production or irreversible external write. A recording request does not itself authorize publishing the video.

## Establish the T3 tab

Call `preview_status`. If no automation-capable tab is attached, call `preview_open`. Inspect actionable errors and correct arguments before concluding the browser is unavailable. Switch browser systems only when T3 tools are absent, open reports explicit unsupported/unavailable, or the user chooses another browser.

Retain `tabId` and pass it to every browser and recording call. Use a dedicated tab for the walkthrough when needed; concurrent agents must each open with `reuseExistingTab=false`. Server tabs have isolated storage and agent-session ownership, so authenticate in the selected tab. Let the user complete an interactive sign-in when credentials cannot be supplied through an authorized flow.

Navigate with `preview_navigate`, using `target:{kind:"environment-port",port:...}` for a local app or `url` for a reachable website. Set the viewport with `preview_resize` and appearance with `preview_set_appearance` if requested. Confirm the actual CSS-pixel viewport through `preview_status` before recording. Treat it as the layout size; the encoded recording can have different pixel dimensions and must be measured separately. Panel visibility and a host's browser execution mode are separate settings; do not promise headed/headless control that the tools do not expose.

Take `preview_snapshot` to inspect the ready page. Prefer its semantic locators for interactions, refreshing references after navigation, another snapshot, or human takeover. Use the focused tools for clicks, typing, selection, keyboard input, scrolling, uploads, and dialogs. Some operations require server browser tabs; host availability and control ownership must support the requested flow.

## Record a representative flow

Read [the T3 framing pattern](references/t3-framing.md) for the temporary page helper and its cleanup. Use it to center and highlight exact controls through `preview_evaluate`; use semantic locators for the interaction itself. Highlighting changes presentation only. Keep application values and behavior controlled by normal browser interactions.

1. Prepare the authenticated starting state before capture, unless sign-in is part of the requested tutorial.
2. Call `preview_recording_start({tabId})` and confirm that recording started.
3. Frame each target, hold briefly, perform its action, wait for the expected app state with `preview_wait_for` or an appropriate state check, then hold the visible result. Start with 400–600 ms before interaction and 600–900 ms afterward; allow longer reading time for dense results.
4. Hold the final verified state, then call `preview_recording_stop({tabId})`. Retain its returned environment-local `path`, MIME type, size, and tab ID. Stop also transfers the compressed recording, up to 50 MiB. Keep long walkthroughs in short labeled segments and retain every returned file.
5. Clear the temporary page helper. On a failed flow, stop an active recording and preserve the failure artifact when possible. Mark its status accurately; inspect an uncertain start/stop response before repeating the operation.

Inspect sample frames from entry, submission, and final state. A successful interaction sequence or nonempty file alone does not prove a readable recording. Fix clipped fields, unreadable labels, or rushed transitions before recording the remaining requested flows. Reset only through the application's supported, authorized flow.

## Package and verify

Record each requested flow separately, in the user's intended order. Serialize flows that share writable state. Keep the raw recording for each flow and note stable IDs of any created records.

When `ffmpeg` and `ffprobe` are available, resolve the bundled script relative to this `SKILL.md` and run:

```sh
bash "<this-skill-directory>/scripts/package_recordings.sh" OUTPUT_DIR "LABEL=RAW_VIDEO" ["LABEL=RAW_VIDEO" ...]
```

It produces silent H.264 MP4 files, a combined video in argument order, and eight sampled frames per flow. The default output size comes from the first recording. Set `GUIDED_VIDEO_WIDTH` and `GUIDED_VIDEO_HEIGHT` together to an explicit even resolution when needed; all clips are padded to that common size without cropping. If audio must be preserved, retain the raw recordings or adapt packaging for that request. If the tools are unavailable, deliver the raw files and report that packaging was skipped.

Probe packaged videos for nonzero duration and inspect each contact sheet with an image tool. Check individual clips where transitions are unclear or brief enough to fall between sampled frames. When the video makes data claims, verify those results through the application API/database or another authoritative app read. Keep credentials out of commands and output; report whether created records remain.

Completion requires every requested flow to have a readable recording and evidence for its claimed outcome, or a clearly identified failure. Remove temporary highlighting, close only tabs created for the walkthrough when appropriate, and restore any app source instrumentation added within the authorized scope. Keep artifacts local until publication is requested.

## Handoff

Report individual and combined artifact links, measured resolution and duration, the recorded flows and their verified outcomes, created record IDs when applicable, and any skipped checks or failed flows. Include enough environment and viewport detail to reproduce the walkthrough. Describe source changes only when the task required them.
