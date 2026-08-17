# MyHomeApp — Claude Instructions

This file contains project-level instructions for Claude Code when working in this repo. Skim it before making changes.

## What this project is

A native iOS client for the MyHomeHub. Built with SwiftUI. The app is currently maintained by a single developer, but it's intended to grow — design choices should be **idiomatic SwiftUI that scales** as features, screens, and contributors are added.

Concretely:

- **Prefer well-maintained libraries over custom reimplementations of common UI/infra patterns** (toasts, popups, charts, image loading, keychain wrappers, etc.) — added via SPM. Custom code is for project-specific logic, not generic infrastructure. Pick libraries with active maintenance, a real user base, and a small API surface; avoid bringing in a framework when a 50-line helper would do.
- **Reach for native SwiftUI patterns first** (`@Observable`, `@Environment`, `NavigationStack`, `.task`, view modifiers). Don't invent a parallel system when SwiftUI already has one.
- **Design for the next contributor**, not just today's feature. Centralize cross-cutting concerns (auth state, error presentation, navigation root) so screens don't each reinvent them, but don't pre-build abstraction layers for needs that don't exist yet.
- **Don't over-engineer.** Skip enterprise patterns (DI containers, repository-over-service-over-data-source stacks, custom reactive frameworks). Idiomatic SwiftUI is the bar; scalability comes from clean boundaries, not from layers.

## Toolchain & targets

| Setting                          | Value                                             |
| -------------------------------- | ------------------------------------------------- |
| Xcode                            | 26.x (latest)                                     |
| Swift                            | 5.0                                               |
| iOS Deployment Target            | **18.6** (app target)                             |
| Devices                          | iPhone + iPad (universal, see `Info` orientations)|
| Concurrency                      | `async`/`await`, `@MainActor` explicit (see below)|
| UI                               | SwiftUI only (no UIKit screens unless required)   |
| Default actor isolation          | **nonisolated** (`SWIFT_DEFAULT_ACTOR_ISOLATION`) |

Use iOS 17+ / iOS 18 APIs freely (e.g. Observation framework `@Observable`, `NavigationStack`, `.scrollTargetBehavior`, etc.). Do not reach for iOS 26-only APIs unless explicitly bumping the deployment target.

## Project structure

```
MyHomeApp/
├── MyHomeApp.swift         # @main entry point
├── ContentView.swift                # Root TabView
├── Assets.xcassets/                 # Colors, images, app icon
├── Core/                            # Models, networking, services (shared infra)
├── Shared/                          # Reusable views, modifiers, extensions
└── Screens/                         # Feature screens
    ├── Home/
    ├── Devices/
    ├── Scenarios/
    └── Settings/

MyHomeAppTests/                # Swift Testing unit tests
├── Mocks/                           # Hand-rolled protocol mocks + fixtures
└── ...                              # Mirrors Screens/Core layout

MyHomeAppUITests/              # XCUITest UI tests (XCTest — Swift Testing
                                     #   doesn't yet cover XCUIApplication,
                                     #   measure, or XCTAttachment)
```

Feature-folder layout. Each `Screens/Foo/` folder owns `FooView.swift`, `FooViewModel.swift`, and feature-local models. Cross-feature code goes in `Core/` or `Shared/`.

## Architecture

MVVM with SwiftUI:

- **Views** (`struct: View`) are dumb. No business logic in `body`. No network calls from `body`. Trigger async work via `.task { }`.
- **ViewModels** are `@Observable` `@MainActor` classes that own state. Inject dependencies via initializer with sensible defaults (`init(service: FooServiceProtocol = FooService.shared)`).
- **Services** expose a `protocol` + concrete implementation. Tests mock the protocol; production uses the concrete type.
- **Models** are `struct`s. Use `Codable`/`Identifiable`/`Equatable`/`Hashable` as needed.
- **Editors use a draft model.** When a screen edits a wire model that is immutable, enum-shaped, or keyed by
  something that isn't a stable list identity, add a `FooDraft` next to the screen: flat, `var`-based, rows
  carry a `UUID`, with `init(foo:)` in and a `payload` out. `Screens/Scenarios/ScenarioDraft.swift` is the
  reference. Don't bend the wire model into a form model.
- **Wire vocabularies the hub owns stay open.** Fields whose values the hub can extend at will (e.g. a
  scenario's `group`) are transparent string wrappers, not closed enums, so an unknown value can't fail
  decoding of a whole page. Closed enums are for vocabularies the app genuinely knows in full.

The full conventions are in [.claude/agents/implementer.md](.claude/agents/implementer.md) and [.claude/agents/reviewer.md](.claude/agents/reviewer.md).

## Build & test

The scheme is **MyHomeApp**. Use an iPhone simulator on iOS 18.x.

The scheme ships two test plans:

- **UnitTests** (default) — unit target only, code coverage off. This is the fast loop; use it for everything except an explicit pre-push/CI check.
- **AllTests** — unit + UI tests, coverage on. Only run this when the user explicitly asks for the UI tests.

```bash
# Build
xcodebuild build \
  -scheme MyHomeApp \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini'

# Run unit tests (fast — no UI tests, no coverage)
xcodebuild test \
  -scheme MyHomeApp \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini' \
  -testPlan UnitTests

# Run everything incl. UI tests (slow — only when explicitly asked)
xcodebuild test \
  -scheme MyHomeApp \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini' \
  -testPlan AllTests

# Lint (requires SwiftLint — see below)
swiftlint
```

Discover available simulators with `xcrun simctl list devices available`.

**Before reporting a task done that touched Swift code, you MUST run both of these and report the result:**

1. `xcodebuild build -scheme MyHomeApp -destination 'platform=iOS Simulator,name=iPhone 13 mini'` — project must build
2. `swiftlint` from the repo root — must have no new errors; address any new warnings your changes introduced

Don't run tests after every change. Run the **UnitTests** plan when the user explicitly asks, or when you've edited files under `MyHomeAppTests/` and need to verify the tests you touched. Always scope to `-testPlan UnitTests` — never run the UI tests (`AllTests`) unless the user explicitly asks for them.

If `iPhone 13 mini` isn't available, check `xcrun simctl list devices available` and pick another iOS 18.x or 26.x simulator. If you cannot run a step (sandbox / tool missing), say so explicitly — do not claim success.

## Linting

[SwiftLint](https://github.com/realm/SwiftLint) is configured via `.swiftlint.yaml` at the repo root. Run `swiftlint` before finishing any task that touched Swift files (see the build & test section — it's part of the mandatory pre-report checks).

## Coding rules (short list — see agent files for full version)

- `struct`/`enum` over `class`. `let` over `var`.
- No force unwraps (`!`) or force casts (`as!`) except for compile-time constants (`URL(string: "...")!`).
- No `print(...)` in production code — use `os.Logger`.
- **Default actor isolation is `nonisolated`.** Mark `@MainActor` explicitly on Views, ViewModels, and anything that mutates UI state. Plain value types (model enums/structs) need no annotation.
- No singletons inside view models — inject via init.
- Use the asset catalog for colors. Don't hardcode hex.
- One primary type per file; file name matches the type.
- Screen-level views get a `#Preview`. For small reusable components, add one only when the canvas would actually help iterate (e.g. multiple states shown side-by-side) — a lone capsule on a 6.7" canvas is noise.

## Test conventions

- **Unit tests use Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`). UI tests remain XCTest until Swift Testing covers `XCUIApplication`.
- Test suite types are `struct`s (not classes). Swift Testing creates a fresh instance per `@Test`, so put fixture setup in `init()` and use stored `let` properties — no `setUp`/`tearDown`.
- Test method names are `camelCase` with **no `test` prefix** (e.g. `loadGroupsDevicesByRoom`). The `@Test` attribute is what marks them as tests.
- Group related tests with `// MARK: -` dividers (e.g. `// MARK: - load() — grouping`). They show up in Xcode's jump bar and minimap.
- Use `#expect(a == b)` for assertions, `#expect(a == b, "message")` to attach context, and `try #require(...)` for **preconditions** the rest of the test depends on — unwrap optionals through `#require`, never through `?` chains or `?? default` inside an `#expect`. `#expect(optional?.x == y)` fails with a confusing boolean message when the optional is `nil`; `#expect(optional ?? sentinel == y)` can pass *vacuously* when `sentinel` happens to equal `y`. Both are silent ways for a broken test to feel fine.
- Use the fluent `Device.fixture()` builder for test devices, not raw `Device(...)` initializers. The builder lives in `MyHomeAppTests/Mocks/Device+Fixture.swift` and exposes semantic methods (`newDevice(...)`, `inRoom(_:)`, `asTuya(...)`, `asZigbee(...)`, `withControls(...)`, etc.).
- Mock service classes conforming to a `Sendable` protocol use `final class … : Protocol, @unchecked Sendable`. Tests serialize their own access.
- Test suites that touch a `@MainActor` ViewModel are themselves `@MainActor` (annotate the `struct`). The ViewModel reference can stay `let` even when the test mutates its properties — it's a reference type.

## Agent workflow

The `.claude/agents/` folder defines five specialized prompts you can invoke:

- **Architect** — plan a feature, no code
- **Implementer** — write the code per the plan
- **Reviewer** — review the diff against project standards
- **Tester** — write Swift Testing unit tests
- **StoryTeller** — write DocC / README docs

See [.claude/agents/README.md](.claude/agents/README.md) for the handoff flow.

Slash commands live in `.claude/commands/`:

- `/tests` — write or adjust unit tests for recent code changes

## Dependencies

- **SPM only** — no CocoaPods or Carthage. Pin versions via `Package.resolved`.
- **Prefer existing libraries for common patterns** (toasts, popups, charts, image loading, keychain, etc.) over rolling your own. Choose libraries that are actively maintained, have a real user base, and have a small API surface.
- Reserve hand-rolled code for project-specific logic (services, models, screens, business rules). Don't reimplement generic UI infrastructure that a maintained package already solves well.

## Things to avoid

- Don't add comments that restate the code (`// Increment counter` above `counter += 1`).
- Don't create planning / decision docs unless explicitly asked.
- Don't add files to the Xcode project that should not be compiled (`README.md`, `.gitignore`, `.swiftlint.yaml`, `LICENSE`). Either leave them out of the project entirely or add them with **all target memberships unchecked**.
- Don't refactor unrelated code while fixing a bug. Keep changes scoped to the request.

## Git

- Default branch: `main`
- Commit messages: short, imperative ("Add device pairing sheet", not "Added").
- Only commit when explicitly asked.
