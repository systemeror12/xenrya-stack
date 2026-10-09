---
name: domain-modeling
description: "Build and sharpen a project's domain model. Use when discussing codebase terminology, writing or editing a GLOSSARY.md, or recording or editing an ADR."
---

# Domain Modeling

Build and sharpen the project's **ubiquitous language** as you design:
challenge terms, invent edge-case scenarios, and write each settled term and
decision down the moment it crystallises.

The glossary and ADRs are **source-of-truth** docs. `specs` builds specs only
from them, and `to-tickets` decision tickets are done when the docs agree with
the answer, so what you write here is what later work treats as fact.

## Where the model lives

Most repos are one **bounded context**:

```
/
├── GLOSSARY.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

A `GLOSSARY-MAP.md` at the root means several bounded contexts. The map names
each one, where it lives, and how it relates to the others:

```
/
├── GLOSSARY-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── GLOSSARY.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── GLOSSARY.md
│       └── docs/adr/
```

Work in the context the topic belongs to, and ask when it is unclear. Create
`GLOSSARY.md` or `docs/adr/` when the first term or ADR settles.

## During the session

When another skill is running the conversation, such as `grilling`, raise
each challenge below in that skill's format.

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in
`GLOSSARY.md`, call it out. "Your glossary defines 'cancellation' as X, but
you seem to mean Y. Which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical
term. "You're saying 'account': do you mean the Customer or the User? Those
are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific
scenarios. Invent scenarios that probe edge cases and force the user to be
precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If
you find a contradiction, surface it: "Your code cancels entire Orders, but
you just said partial cancellation is possible. Which is right?"

### Write the glossary as terms settle

Add or update the entry as soon as the user settles a term:

```md
**Cancellation**:
A request to withdraw approved leave, in whole or for dates at either end.
_Avoid_: Revocation, withdrawal
```

An entry says what the term means in the domain, in one or two sentences, and
lists the rejected synonyms under `_Avoid_`. Behaviour and implementation
belong in specs, code, and ADRs.

### Offer ADRs sparingly

Offer an ADR only when all three are true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful.
2. **Surprising without context**: a future reader will wonder "why did they
   do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and
   you picked one for specific reasons.

An accepted ADR is `docs/adr/NNNN-<slug>.md`, numbered after the highest
existing one: a title, then a short paragraph of context, decision, and
reason.

Done when every term the session settled is in the glossary, and every
decision that meets all three tests has been offered as an ADR.
