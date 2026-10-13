---
name: prototype
description: "Prototype a UI as at least three switchable variants (A, B, C), each at a live URL and shown with its fonts and color hex codes."
disable-model-invocation: true
---

# Prototype

Build each round as variants the user can open, flip between, and pick from. A round is done when every variant has a live link, the variants link to each other, and the user can see the fonts and colors each one uses.

## Rules

1. **At least three variants: A, B, C.** Build more than three only when the user asks for more, and follow the user when they name a set ("A and B only"). Make each variant a distinct direction, not the same design with small changes.
2. **Navigation from the first round.** Every variant page has a small switcher fixed in a corner. It lists every variant in the round (A · B · C), marks the current one, and links to the others. It works at phone width, doesn't cover content, and stays visually apart from the design. When the variants differ in only one section of a page, use one file with a query parameter (`?v=b`) and the same switcher. When iterating on a winner, the switcher also lists the winner so the user can compare.
3. **Always give the URL.** Serve the prototypes and give a clickable URL for every variant. Use the project's dev server if it serves the files, otherwise a static server on a free port. Run it in the background with the longest timeout allowed, and load each URL once before sending it. If the server will stop, say when and also give the `file://` path.
4. **Always show fonts and colors.** For every variant, show the font pairing and the palette as swatches with hex codes. Say where a color comes from when it has a source, for example "#bb6688 is Kanade's official image color."
5. **Theme is your call.** When the user asks for a new look or gives a reference to capture (a character, mood, or brand), give each variant a concept and say briefly how it expresses that reference. When the request is to adjust a component inside an existing design, keep the existing theme, vary only the component, and skip the concept.

## Round

1. **Gather.** Read the content and any wording rules (`CONTEXT.md`, content modules). Treat reference images as sources of palette and motifs. Use the `frontend-design` skill for direction if it is available. For an overhaul, take only the content and don't reuse the current design. When the user locks parts ("keep the hero and its fonts"), copy them unchanged into every variant and vary only the parts still open.
2. **Build.** Make each variant a self-contained HTML file under `prototypes/`, with a subfolder per round once there are several rounds. Don't change the app's source. Use the real content and don't invent claims. Draw motifs from scratch instead of embedding reference artwork the user doesn't own.
3. **Check.** Look at each variant at 1440px and 390px wide. Check for console errors and sideways scrolling, text contrast of at least 4.5:1, visible keyboard focus, and that reduced motion stops all animation. Fix what you find before showing anything. Use `html_preview` or a headless browser for sharp screenshots; the T3 preview tab captures at low resolution.
4. **Show.** Publish one comparison with `html_render`. For each variant, show its screenshot, palette swatches with hex codes, and fonts, plus the reference images if there are any. If the T3 preview tab is available, open your pick in it.
5. **Reply.**

   **Links**
   - **A · <name>:** <url>. <what to try: the interaction or motion to watch>
   - **B · <name>:** …
   - **C · <name>:** …

   **Fonts and colors:** one line per variant: `<display font> + <body font> · #hex #hex …`

   **My pick:** <variant>, then one trade-off per variant and any mixes that would work.

   End with where the files are, a note that the app's source is unchanged, and a question about which variant or mix to take forward.

## Next rounds

- **A winner, more wanted:** keep the winner unchanged and build at least three new variants in its spirit, named after it (A2, A3, A4).
- **Feedback on one prototype** (a detail is wrong, it should follow a reference more closely): this is a refinement, not a new round. Edit that prototype in place, show a before/after image, check it again, and send its link again. Give the hex code of any color you changed.
- **Settled:** strip the losing variants and the switcher from the chosen file so it shows only the winner. Commit, push, or record decisions on an issue only when the user asks. The settled prototype is then the input for `to-tickets`.
