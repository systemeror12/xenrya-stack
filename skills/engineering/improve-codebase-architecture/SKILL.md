---
name: improve-codebase-architecture
description: "Use for \"improve the architecture\", \"architecture review\", \"deepening opportunities\", \"shallow modules\", or \"what should we refactor\". Finds shallow modules worth deepening, shows them as a before/after report in the thread, then grills the one you pick."
disable-model-invocation: true
metadata:
  upstream-author: "Matt Pocock"
  upstream-project: "mattpocock/skills"
  upstream-source: "https://github.com/mattpocock/skills/tree/d80fa0f4ebe0c5714af0adf8670336065233ecc6/skills/engineering/improve-codebase-architecture"
  upstream-license: "MIT"
  adaptation: "T3 Code html_render report; codebase-design vocabulary folded in"
---

# Improve Codebase Architecture

Find the codebase's **friction** and propose **deepening** opportunities: refactors that turn shallow modules into deep ones, so the code gets easier to test and for agents to navigate. The deliverable is a report of candidates in the thread, then a grilling of the one the user picks.

The phases run **scope → explore → shortlist → report → grill → hand off**. The report ends a turn; the user's pick starts the next.

## Hard rules

- **Use the [vocabulary](#vocabulary) exactly**, in the explorer's brief, the report, and the grilling. Each _Avoid_ word ("service", "boundary") splits the signal and drifts into vague advice.
- **Each candidate says what changes, in plain words.** Its interface is designed in the grilling, with the user, after the pick: an interface in the report anchors the choice before the user has weighed the candidates.

## Vocabulary

| Term | Meaning | _Avoid_ |
| --- | --- | --- |
| **Module** | Anything with an interface and an implementation: a function, class, package, or a slice across tiers. | unit, component, service |
| **Interface** | Everything a caller must know to use the module: types, invariants, ordering, error modes, configuration, performance. | API, signature |
| **Implementation** | The code inside a module. | |
| **Depth** | The behaviour a caller or test can exercise per unit of interface it must learn. **Deep**: much behaviour behind a small interface. **Shallow**: the interface is nearly as complex as the implementation. | |
| **Seam** | Where a module's interface lives: a place where behaviour can change without editing there. | boundary |
| **Adapter** | A concrete thing that satisfies an interface at a seam. | |
| **Leverage** | What callers get from depth: one implementation pays back across every caller and test. | |
| **Locality** | What maintainers get from depth: change, bugs, and verification concentrate in one module. | |

- **The deletion test.** Imagine deleting the module and inlining it into its callers. If the complexity vanishes or concentrates, the module was a pass-through, and that is a candidate. If it reappears across many callers, the module earns its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. A test that has to reach past the interface means the module is the wrong shape.
- **One adapter is a hypothetical seam; two make it real.** Propose a seam only where something varies across it, typically production and test.
- **Depth belongs to the interface.** A deep module may be built from small parts inside; they stay out of its interface.

Each candidate's **dependency category** decides how the deepened module is tested across its seam:

| Category | Its dependencies | Tests use |
| --- | --- | --- |
| `in-process` | Pure computation, in-memory state | The module directly, no adapter |
| `local-substitutable` | Something with a local stand-in, such as PGLite or an in-memory filesystem | The stand-in, inside the test suite |
| `ports & adapters` | Your own services across a network | An in-memory adapter; production uses the HTTP or queue adapter |
| `mock` | Third-party services, such as Stripe | A mock adapter on an injected port |

Domain concepts take their glossary terms: "the Order intake module", not "the FooBarHandler" or "the Order service".

## Steps

1. **Scope.** Decide where to look before you look. Deepening pays off by making future change easier, so weight the code that changes most.
   - When the user named a direction, such as a module, a subsystem, or a pain point, take it.
   - Otherwise find the hot spots in the history, such as `git log -n 300 --name-only --format= | sort | uniq -c | sort -rn | head -40`. When change is scattered with no clear hot spot, widen the net.

   Then read the domain docs for those areas: the glossary and the ADRs, where `docs/agents/domain.md` says they live, or `GLOSSARY.md` and `docs/adr/` at the root when it doesn't exist. Carry on without the ones that are missing. Done when you can name each area to explore, why it was chosen, and the glossary terms and ADRs that cover it.
2. **Explore.** Dispatch one read-only explorer subagent so its file reads stay out of this thread: the Agent tool with the `Explore` type in Claude Code, a native subagent in Codex. Run the exploration yourself only when neither is available. Send it this brief, filled in:

   ```text
   Read-only: change nothing. Walk <areas> in <absolute checkout path> and report where the code causes friction. Explore freely; these questions start you off:
   - Where does understanding one concept mean bouncing between many small modules?
   - Where is a module shallow, its interface nearly as complex as its implementation?
   - Where were pure functions extracted for testability while the bugs hide in how they are called?
   - Where do tightly coupled modules leak across their seams?
   - What is untested, or hard to test through its current interface?
   Apply the deletion test to each module you suspect is shallow: imagine inlining it into its callers. Does the complexity vanish or concentrate, or reappear across callers?
   Use these terms exactly: module, interface, implementation, depth, deep, shallow, seam, adapter, leverage, locality. Name domain concepts with these glossary terms: <terms>.
   Return each friction point with its files, what hurts in one sentence, its deletion-test result, its dependencies, and the tests that cover it today. Return findings only, without fixes or interfaces.
   ```

   Done when the explorer has reported and you have read the key files behind every finding you might present.
3. **Shortlist.** Group the findings that one deepening would fix into a candidate. Give each a strength (`Strong`, `Worth exploring`, or `Speculative`) and a dependency category, and check it against the ADRs: keep a candidate that contradicts an ADR only when its friction is real enough to reopen the ADR, and say why in its card. Rank strongest first, and put about three on the page, since T3's frame stops at 2000px. Done when every candidate has its files, problem, solution, wins, strength, category, and ADR check.
4. **Report.** Build the page from [`references/report.md`](references/report.md), check it with `html_preview`, and show it with `html_render`. In Claude Code, load both with `select:mcp__t3-code__html_preview,mcp__t3-code__html_render`; in Codex they are `mcp__t3_code__html_preview` and `mcp__t3_code__html_render`. Outside a T3 thread, give each card as markdown in the reply instead, without diagrams.

   Your reply adds only what the page doesn't say: the scope you chose and why, and the candidates that didn't fit on the page, one line each. End with "Which of these would you like to explore?" and end the turn. Done when the page passes the checks in `report.md` and is shown in the thread.
5. **Grill.** When the user picks a candidate, run the `grilling` skill on it. It is user-invoked, so read this repo's copy at [`../../productivity/grilling/SKILL.md`](../../productivity/grilling/SKILL.md) and follow it. It keeps `domain-modeling` running, which writes each settled term to the glossary. The design tree covers the constraints, the dependencies, the deepened module's interface, what sits behind the seam, and which tests survive:
   - **Replace, don't layer.** New tests assert observable outcomes through the deepened module's interface; the old tests on the shallow modules are deleted once those exist. A test that must change when the implementation changes is testing past the interface.
   - **Alternative interfaces.** When the user wants to compare interface designs, follow [`references/design-it-twice.md`](references/design-it-twice.md).
   - **A rejection with a load-bearing reason.** Offer an ADR: "Want me to record this as an ADR so future architecture reviews don't re-suggest it?" Offer it only when a future review would need the reason to avoid suggesting the candidate again. Skip reasons like "not now" and reasons any reader would see.

   Done when the grilling's frontier is empty and the user confirms a shared understanding of the deepened module.
6. **Hand off.** Reply with the settled design: the deepened module and its interface, what sits behind the seam and its adapters, the tests that replace the old ones, and the glossary terms and ADRs written. It is the input for `specs`, or for `to-tickets` when one PR covers it. File, implement, or commit only when the user asks. Done when the settled design is in the thread.
