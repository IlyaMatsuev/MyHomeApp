# Planning guide

How to plan a feature before writing it. Plan first, no code yet; whoever plans then implements, so the plan
records decisions rather than instructing a stranger.

## Skills to use

Invoke these before writing the plan, in this order:

1. **`ponytail:ponytail`** — plan the smallest change that fully solves the request. Check whether each
   proposed file needs to exist, whether an existing screen / service / store already covers it, and cut
   any layer, option or flag nobody asked for. Name what you deliberately skipped in the plan.
2. **`swift-architecture-skill`** — read `references/mvvm.md` for structure, state ownership, async and
   testing detail when a feature's shape isn't obvious from the nearest existing screen. The repo's copy is
   trimmed to MVVM; the architecture here is settled, so there is nothing to select.

Where a skill and this file disagree, **this file and [CLAUDE.md](../../CLAUDE.md) win.** The known
conflicts are resolved once in
[CLAUDE.md § Skill conflicts](../../CLAUDE.md#skill-conflicts--resolved-once-here) — apply those and move on.

Ponytail's "smallest change" and CLAUDE.md's "consistency beats a smaller diff" resolve the same way:
follow the established convention, and be lazy about inventing *new* structure, never about reusing the
existing structure.

## Project Context

The toolchain, folder layout, architecture and coding rules are in [CLAUDE.md](../../CLAUDE.md). Read its
**Toolchain & targets**, **Project structure**, **Architecture** and **Coding rules** sections — they are
the authority and there is no second copy here. [implementing.md](implementing.md#project-patterns) shows the
same patterns as working code (loader/screen, router, service, draft); skim it when you need the exact
shape you're planning toward.

Two things that bear on planning specifically:

- **Plan the `buildFooViewModel(...)` call on `AppContainer`**, not a new DI mechanism. No resolver, no
  repository-over-service stack, no `.shared`, no default service arguments, no custom `EnvironmentValues`
  `@Entry` keys.
- **A store is for state that outlives a screen** — don't plan one before that's true. A view model takes
  the store *or* that feature's service, never both.

Feature-local models live under that feature (`Core/Devices/Models/`, or next to the screen for a
`FooDraft`). There is no `Core/Models/` folder.

## Planning Process

When given a feature request:

1. **Understand Requirements**
    - Start from the settled requirements; don't reopen them
    - If something still open would change the design, stop and ask the user, with a recommended answer
    - Identify user-facing vs internal changes
    - Determine scope boundaries (which screens / flows are touched)

2. **Impact Analysis**
    - List affected screens / folders
    - Identify new files needed (View, ViewModel, Service, Model)
    - Note breaking changes to public API or persisted data

3. **Design Decisions**
    - Choose appropriate patterns (sheet vs push, `@State` vs `@Observable`, etc.)
    - Define model and view-model contracts
    - Plan navigation changes (`NavigationStack`, `TabView`, sheets)
    - Design service interfaces (protocols + DTOs)

4. **Task Breakdown**
    - Create ordered tasks
    - Specify file paths for each task
    - Note dependencies between tasks

5. **Risk Assessment**
    - Identify potential issues (concurrency, main-actor isolation, lifecycle)
    - Note backward compatibility concerns (min iOS version, persisted data)
    - Suggest rollback strategies

## Output

Short and inline; scale it to the change and leave out any part with nothing to say:

- **Approach** — two or three sentences, and what you deliberately skipped.
- **Files** — new and changed, one line of purpose each, in implementation order.
- **Contracts** — signatures for new models, view models and services, with their actor isolation.
- **UX** — how the user gets in and out, plus the empty, loading and error states.
- **Wire / persistence** — endpoints, payloads, and what happens to data already saved on a device.
- **Tests** — the behaviours worth pinning.
- **Risks** — only real ones, with what you'll do about each.

## Guidelines

- Always check existing patterns before proposing new ones — open the closest screen folder first.
- Prefer extending an existing screen / service over creating a new one.
- Follow the project's existing convention even when a local one-off would be smaller.
- Design for testability: protocols for services, `@Observable` view models, no singletons.
- Say which work is on the main actor and which isn't, and mark `@MainActor` in the contracts you write.
- Think about accessibility (Dynamic Type, VoiceOver labels) and dark mode from the start, not after.
