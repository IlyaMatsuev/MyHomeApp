---
name: swift-architecture-skill
description: MVVM playbook for SwiftUI iOS codebases — structure, state ownership, dependency boundaries, async strategy and testing. Use when designing or reviewing the architecture of a SwiftUI feature.
license: MIT
---

# Swift Architecture Skill

MVVM playbook for SwiftUI. This repo's copy has been trimmed to MVVM only: the architecture
decision here is settled (see [CLAUDE.md](../../../CLAUDE.md#architecture)), so the upstream
skill's selection guide, fit check, Deep Refactor Mode and the MVI / TCA / Clean / VIPER / MVP /
Coordinator / Reactive playbooks were removed rather than carried as dead weight.

## References

- `references/mvvm.md` — structure, state ownership, dependency boundaries, async and testing.
  The main playbook; read it when a feature's shape isn't obvious from the nearest existing screen.
- `references/concurrency.md` — cancellation, stale-response guards, error mapping in async code.
- `references/observation.md` — `@Observable` wiring. Ignore its `ObservableObject` / iOS 16–17
  branches; this project is iOS 26 and uses Observation unconditionally.

## Deliverables

Convert the playbook into guidance tailored to the request:

- **File and module structure** — directory layout with names specific to the feature
- **State and dependency boundaries** — concrete types, protocols, injection points
- **Async strategy** — cancellation, actor isolation, error paths
- **Testing strategy** — what to test, how to stub dependencies, example test structure

## Guardrails

- Scope recommendations to the requested feature; don't dump the playbook.
- Preserve existing conventions. Flag a one-off that diverges from them, not the convention itself.
- Protocol-based dependency injection and explicit state modelling.
- Include cancellation and error handling in every async flow.
- Treat snippets as illustrative unless the user asks for runnable code.
- State assumptions up front instead of asking non-blocking questions.
