# Design It Twice

The alternative-interfaces branch of [`improve-codebase-architecture`](../SKILL.md): when the user wants to compare interface designs for the picked candidate, several agents each design it a radically different way. Your first idea is unlikely to be the best (Ousterhout).

1. **Frame.** Show the user the problem space: the constraints any new interface must satisfy, the dependencies and their category, and a rough code sketch that makes the constraints concrete. The sketch illustrates the constraints; it doesn't propose an interface. Done when the framing is in the thread.
2. **Dispatch.** In the same turn, dispatch three or four read-only designers in parallel, following `delegate-subagents` phases 2–4 (this repo's copy is [`../../../orchestration/delegate-subagents/SKILL.md`](../../../orchestration/delegate-subagents/SKILL.md)). Give each the same brief, with the files, the coupling, the dependency category, what sits behind the seam, the [vocabulary](../SKILL.md#vocabulary), and the glossary terms, plus one constraint of its own:
   - "Minimise the interface: one to three entry points, maximum leverage per entry point."
   - "Maximise flexibility: support many use cases and extension."
   - "Optimise for the most common caller: make the default case trivial."
   - "Design around ports and adapters for the dependencies that cross the seam," when there are any.

   Each designer returns its interface (types, methods, parameters, invariants, ordering, error modes), a usage example from a caller, what the implementation hides behind the seam, its adapters, and where its leverage is high and where it is thin. Done when every designer is recorded as `delegate-subagents` phase 3 describes, and the user knows which are running.
3. **Compare.** When the designs are in, present them one at a time, then compare them by depth, locality, and seam placement. Recommend the strongest, or a hybrid when parts of different designs combine well. Be opinionated: the user wants a strong read, not a menu. Done when the comparison and your recommendation are in the thread, and the grilling resumes on the user's choice.
