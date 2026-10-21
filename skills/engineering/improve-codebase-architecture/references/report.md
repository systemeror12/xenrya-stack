# Report

The report branch of [`improve-codebase-architecture`](../SKILL.md): the page `html_render` shows in the thread, its scaffold, the diagram patterns, the checks, and the tone.

## The frame

- **Inline in the reply.** T3 renders the page above your reply, as wide as the reply column: 728px on desktop and about 360px on phones. Keep the outermost element fluid with no horizontal padding, leave `html` and `body` without a background, and add no outer card or banner title.
- **Theme colours only.** Colour comes from T3's theme variables (`--foreground`, `--card`, `--destructive`, `--chart-1`, …), which follow the user's theme and its light and dark modes. A hard-coded colour breaks in one of the two modes.
- **Static HTML and CSS.** `html_preview` screenshots and measures the page right after load, so anything a script draws later, such as a Mermaid diagram from a CDN, is missing from the check and from `contentHeight`, and `html_render` would size the frame too short. Draw every diagram with the scaffold's classes or inline SVG.
- **Under 2000px tall at 728px**, `html_render`'s frame limit: about three cards. Phones stack the panes, so two cards already reach about 1900px there, and anything past 2000px scrolls inside the frame.

## Page

A legend, one `<article>` card per candidate in rank order, then the top recommendation. Each card holds:

- **Head:** the number the user will answer with, a title that names the deepening ("Collapse the Order intake pipeline"), a strength badge (`strong`, `explore`, or `speculative`), and the dependency category as a tag.
- **Files:** the modules involved, in one monospaced line.
- **Before / After:** the centrepiece, two panes side by side that stack on phones. Use one [pattern](#diagram-patterns) per pair, and vary the patterns across cards.
- **Problem:** one sentence on what hurts.
- **Solution:** one sentence on what changes.
- **Wins:** bullets of six words or fewer, in the vocabulary.
- **ADR callout**, when the candidate contradicts an ADR: one line naming it and why it is worth reopening.

The top recommendation names one candidate and gives one sentence on why it goes first.

## Scaffold

Copy it whole and replace the example card. Every class the patterns use is in its `<style>`.

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<style>
  body { font: 14px/1.55 var(--font-sans); }
  code { font-family: var(--font-mono); }

  .legend { display: flex; flex-wrap: wrap; gap: 6px 18px; margin-bottom: 4px; font-size: 12px; color: var(--muted-foreground); }
  .legend span { display: inline-flex; align-items: center; gap: 6px; }
  .key { width: 18px; height: 12px; border: 1px solid var(--muted-foreground); border-radius: 3px; }
  .key-deep { border: 3px solid var(--foreground); }
  .key-seam, .key-leak { height: 0; border: 0; border-radius: 0; border-top: 2px dashed var(--accent); }
  .key-leak { border-top: 2px solid var(--destructive); }

  article { padding: 24px 0; border-top: 1px solid var(--border); }
  .head { display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px 10px; }
  .head h2 { margin: 0; font-size: 17px; font-weight: 600; }
  .num { font: 600 13px var(--font-mono); color: var(--muted-foreground); }
  .badge { display: inline-flex; align-items: center; gap: 6px; padding: 1px 9px; border: 1px solid var(--border); border-radius: 999px; font-size: 11px; font-weight: 600; }
  .badge::before { content: ""; width: 7px; height: 7px; border-radius: 50%; background: var(--dot); }
  .strong { --dot: var(--success); }
  .explore { --dot: var(--warning); }
  .speculative { --dot: var(--muted-foreground); }
  .tag { font: 11px var(--font-mono); color: var(--muted-foreground); }
  .files { margin: 8px 0 16px; font: 12px/1.6 var(--font-mono); color: var(--muted-foreground); overflow-wrap: anywhere; }

  .ba { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  @media (max-width: 560px) { .ba { grid-template-columns: 1fr; } }
  .pane { padding: 16px; border-radius: var(--radius); background: var(--card); color: var(--card-foreground); }
  .cap { margin-bottom: 12px; font-size: 11px; letter-spacing: .08em; text-transform: uppercase; color: var(--muted-foreground); }

  .mod { padding: 6px 10px; border: 1px solid var(--muted-foreground); border-radius: 6px; font: 12px/1.3 var(--font-mono); }
  .mod.deep { padding: 10px 12px; border: 3px solid var(--foreground); font-weight: 600; }
  .mod.leak { border-color: var(--destructive); color: var(--destructive); }
  .inner { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; font-weight: 400; }
  .inner .mod { border-style: dashed; opacity: .5; }
  .flow { display: flex; flex-direction: column; align-items: flex-start; gap: 2px; }
  .arrow { padding-left: 12px; font-size: 12px; color: var(--muted-foreground); }
  .arrow.leak { color: var(--destructive); }
  .seamline { margin: 12px 0 10px; border-top: 2px dashed var(--accent); }
  .seamline::after { content: "seam"; display: block; margin-top: 2px; font-size: 11px; color: var(--accent); }
  .row { display: flex; flex-wrap: wrap; gap: 8px; }
  .note { margin-top: 10px; font-size: 12px; color: var(--muted-foreground); }

  .band { padding: 6px 10px; border-left: 4px solid var(--muted-foreground); background: var(--muted); font: 12px var(--font-mono); }
  .band + .band { margin-top: 4px; }
  .band.thick { padding: 22px 12px; border-left-color: var(--foreground); font-weight: 600; }

  .mass { display: flex; align-items: flex-end; gap: 14px; height: 150px; }
  .mass figure { display: flex; flex-direction: column; align-items: center; gap: 4px; margin: 0; font-size: 11px; color: var(--muted-foreground); }
  .bars { display: flex; align-items: flex-end; gap: 3px; }
  .bar { width: 18px; border-radius: 3px 3px 0 0; }
  .iface { background: var(--chart-2); }
  .impl { background: var(--chart-1); }
  .swatch { display: inline-block; width: 10px; height: 10px; margin: 0 4px 0 10px; border-radius: 2px; }

  svg.graph { display: block; width: 100%; height: auto; overflow: visible; }
  .graph rect { fill: none; stroke: var(--muted-foreground); }
  .graph text { fill: var(--foreground); font: 11px var(--font-mono); }
  .graph .edge { stroke: var(--muted-foreground); marker-end: url(#arrow); }
  .graph .edge.leak { stroke: var(--destructive); stroke-dasharray: 4 3; marker-end: url(#arrow-leak); }
  .graph .node.leak rect { stroke: var(--destructive); }
  #arrow path { fill: var(--muted-foreground); }
  #arrow-leak path { fill: var(--destructive); }

  dl { display: grid; grid-template-columns: 76px 1fr; gap: 6px 12px; margin: 16px 0 0; }
  dt { padding-top: 1px; font-size: 12px; color: var(--muted-foreground); }
  dd { margin: 0; }
  dd ul { margin: 0; padding-left: 18px; }
  .adr { margin-top: 14px; padding: 10px 14px; border-left: 3px solid var(--warning); border-radius: 0 var(--radius) var(--radius) 0; background: var(--warning-surface); font-size: 13px; }

  .top { margin-top: 8px; padding: 18px; border-radius: var(--radius); background: var(--accent-surface); color: var(--accent-surface-foreground); }
  .top .cap { color: inherit; opacity: .8; }
  .top h2 { margin: 0 0 4px; font-size: 17px; }
  .top p { margin: 0; }
</style>
</head>
<body>
  <svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z"/></marker>
    <marker id="arrow-leak" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z"/></marker>
  </defs></svg>

  <div class="legend">
    <span><i class="key"></i>module</span>
    <span><i class="key key-deep"></i>deep module</span>
    <span><i class="key key-seam"></i>seam</span>
    <span><i class="key key-leak"></i>leakage</span>
  </div>

  <article>
    <div class="head">
      <span class="num">1</span>
      <h2>Collapse the Order intake pipeline</h2>
      <span class="badge strong">Strong</span>
      <span class="tag">in-process</span>
    </div>
    <div class="files">src/orders/handler.ts · validator.ts · normalizer.ts · repo.ts</div>
    <div class="ba">
      <div class="pane">
        <div class="cap">Before</div>
        <div class="flow">
          <div class="mod">OrderHandler</div>
          <div class="arrow">↓ validate(raw)</div>
          <div class="mod">OrderValidator</div>
          <div class="arrow">↓ normalize(order, opts)</div>
          <div class="mod">OrderNormalizer</div>
          <div class="arrow">↓ save(order, tx)</div>
          <div class="mod leak">OrderRepo</div>
          <div class="arrow leak">↳ reads PricingClient directly</div>
        </div>
      </div>
      <div class="pane">
        <div class="cap">After</div>
        <div class="flow">
          <div class="mod">OrderHandler</div>
          <div class="arrow">↓ intake</div>
          <div class="mod deep">Order intake
            <div class="inner"><span class="mod">validate</span><span class="mod">normalize</span><span class="mod">save</span></div>
          </div>
        </div>
      </div>
    </div>
    <dl>
      <dt>Problem</dt><dd>Order intake is spread over four shallow modules whose interfaces match their implementations.</dd>
      <dt>Solution</dt><dd>Merge them into one Order intake module, tested through its own interface.</dd>
      <dt>Wins</dt><dd><ul><li>Locality: intake bugs live in one module</li><li>Tests hit one interface</li><li>Delete three pass-through modules</li></ul></dd>
    </dl>
    <!-- Only when the candidate contradicts an ADR: -->
    <div class="adr">Contradicts ADR-0007 (validate at the edge), but worth reopening: every caller now validates twice.</div>
  </article>

  <div class="top">
    <div class="cap">Top recommendation</div>
    <h2>1 · Collapse the Order intake pipeline</h2>
    <p>Every fix this quarter touched three of its four modules.</p>
  </div>
</body>
</html>
```

## Diagram patterns

Each pattern fits a pane about 330px wide. Pick the one that shows this candidate's friction.

- **Flow**, for a call that hops through shallow modules: `.flow` holding `.mod` boxes and `.arrow` lines, as in the scaffold. Mark leakage with `.mod.leak` and `.arrow.leak`.
- **Collapse**, for the after side of a flow: one `.mod.deep` with its former modules faded inside `.inner`, as in the scaffold.
- **Seam and adapters**, for a dependency moving behind a port:

  ```html
  <div class="mod deep">Pricing</div>
  <div class="seamline"></div>
  <div class="row"><span class="mod">HttpPricing</span><span class="mod">InMemoryPricing</span></div>
  <div class="note">Two adapters justify the seam: HTTP in prod, in-memory in tests.</div>
  ```

- **Cross-section**, for layers a call passes through: thin `.band`s before, one `.band.thick` after.

  ```html
  <div class="band">authMiddleware</div><div class="band">sessionLoader</div><div class="band">sessionGuard</div>
  <!-- after -->
  <div class="band thick">Session: load, guard, store</div>
  ```

- **Mass**, for an interface as wide as its implementation: an interface bar and an implementation bar per module, with heights in px. Before, the bars are nearly equal; after, the interface bar is short.

  ```html
  <div class="mass">
    <figure><div class="bars"><div class="bar iface" style="height:110px"></div><div class="bar impl" style="height:120px"></div></div>before</figure>
    <figure><div class="bars"><div class="bar iface" style="height:24px"></div><div class="bar impl" style="height:130px"></div></div>after</figure>
  </div>
  <div class="note"><i class="swatch iface"></i>interface<i class="swatch impl"></i>implementation</div>
  ```

- **Graph**, for dependencies that cross: inline SVG on a 300-wide `viewBox`, using the arrow markers the scaffold defines once.

  ```html
  <svg class="graph" viewBox="0 0 300 170" role="img" aria-label="Three modules call PricingClient directly">
    <g class="node"><rect x="4" y="8" width="110" height="28" rx="5"/><text x="59" y="26" text-anchor="middle">OrderRepo</text></g>
    <g class="node"><rect x="4" y="70" width="110" height="28" rx="5"/><text x="59" y="88" text-anchor="middle">CartTotal</text></g>
    <g class="node"><rect x="4" y="132" width="110" height="28" rx="5"/><text x="59" y="150" text-anchor="middle">Checkout</text></g>
    <g class="node leak"><rect x="180" y="70" width="116" height="28" rx="5"/><text x="238" y="88" text-anchor="middle">PricingClient</text></g>
    <line class="edge leak" x1="114" y1="22" x2="178" y2="78"/>
    <line class="edge leak" x1="114" y1="84" x2="178" y2="84"/>
    <line class="edge leak" x1="114" y1="146" x2="178" y2="90"/>
  </svg>
  ```

## Checks

Preview the page three times with `html_preview`: at width 728 in dark, at 728 in light, and at 390. On each screenshot, look for:

- a console error or warning;
- a diagram that is clipped, overlaps its pane, or scrolls sideways;
- text that is hard to read against its background.

Fix what you find and preview again. Then call `html_render` with a short title, such as "Architecture review: <repo>", and `height` set to the 728px preview's `contentHeight`.

## Tone

The diagrams carry the weight. When a diagram needs a paragraph to be understood, redraw the diagram.

The architecture words come from the [vocabulary](../SKILL.md#vocabulary) and the domain words from the glossary. Phrasings that fit:

- "Order intake module is shallow: its interface nearly matches its implementation."
- "Pricing leaks across the seam."
- "Deepen: one interface, one place to test."
- "Two adapters justify the seam: HTTP in prod, in-memory in tests."

Wins name the gain in those terms: "locality: bugs concentrate in one module", "leverage: one interface, three callers", "the interface shrinks; the implementation absorbs the wrappers". When a sentence could be a bullet, make it a bullet; when a bullet could be cut, cut it.
