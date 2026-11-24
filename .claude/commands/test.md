---
description: Write or adjust unit tests for recent code changes, then review them
argument-hint: [scope — defaults to the last commit plus uncommitted changes]
---

Write tests for my recent code changes, then have them reviewed.

**Scope:** $ARGUMENTS

## 1. Resolve the scope

- **If a scope is given above**, use exactly that — a type, a file, a folder, a feature, a commit range,
  whatever I named. Don't widen it to the rest of the diff.
- **If it's empty**, default to my recent changes: the last commit plus any uncommitted working-tree
  changes (`git show HEAD` and `git diff`).

Don't create a worktree when the scope includes uncommitted changes: they exist only in this checkout.
Otherwise follow [CLAUDE.md § Worktrees](../../CLAUDE.md#worktrees).

Then read the actual change before writing anything, and state in one line what you resolved the scope
to and which files it covers. Derive that file list from the resolved scope — for the empty-scope default
that's `git diff --name-only HEAD~1` (last commit through the working tree), but for an explicit scope it's
whatever files that scope names.

If the scope is ambiguous, or the intended behaviour isn't clear enough to assert (bug or feature?), ask me
now — all questions at once, each with your recommended answer — and wait. Otherwise proceed.

## 2. Write the tests

Write them yourself, following [../guides/testing.md](../guides/testing.md):

- **Validate the production code first.** Read the diff and confirm the code is correct before writing
  tests. Flag anything that looks wrong in the final report.
- **Don't pause for confirmation before writing.** Requirements were settled in §1. If intended
  behaviour still turns out to be unclear, ask instead of pinning a guess.
- **Don't change production code.** Only add or modify files under `MyHomeAppTests/`. The one case to stop
  and ask about is a test that genuinely cannot be written without a production change (e.g. a service
  isn't behind a protocol) — ask rather than reshaping production code to suit a test.
- **Match the existing test style and structure** in the affected test files.
- **Keep XCTest out of the unit target.** New unit tests are Swift Testing; `MyHomeAppUITests/` stays
  XCTest.
- Move or rename tests alongside anything the implementation moved or renamed, instead of duplicating.
- Run the affected tests, then the whole unit suite, via the **UnitTests** plan and confirm green before
  reporting.

## 3. Dispatch `reviewer` — scoped to the tests

Pass it the absolute path to work in, the resolved scope and file list, the intended behaviour with my
answers, and the UnitTests result so it doesn't rerun them.

The reviewer's checklist is written for production code, so **tell it explicitly what to look at here**,
and that most of its sections do not apply:

- **Do the assertions pin the behaviour?** A test that passes whatever the code does is worthless.
- **Vacuous passes.** `#expect(optional?.x == y)` failing confusingly on `nil`, and
  `#expect(optional ?? sentinel == y)` passing when `sentinel == y`. Both must be `try #require(...)`.
- **Project conventions:** `struct` suites, fixture setup in `init()` (no `setUp`/`tearDown`), camelCase
  names with **no** `test` prefix on `@Test` methods, `@MainActor` on suites touching a `@MainActor` view
  model, `Foo.fixture()` builders rather than raw initializers, `Stub*` types from `MyHomeAppTests/Mocks/`.
- **No XCTest in the unit target.** `XCTAssert` / `setUp` / `XCTestCase` belong only in
  `MyHomeAppUITests/`.
- **Coverage gaps worth naming:** an error path, an edge case, or a cancellation path the tests skipped.
- **Real bugs the tests reveal** in the production code under test — report them, don't fix them.

Tell it to **skip** §3 SwiftUI Patterns, §8 Accessibility & UX and §9 Architecture Alignment: there is no
UI or architecture in a test file, and firing those sections here produces noise.

## 4. Act on the review

Fix what stands — test-side fixes only. Drop findings that contradict
[CLAUDE.md § Skill conflicts](../../CLAUDE.md#skill-conflicts--resolved-once-here) or the test conventions
(XCTest style in the unit target, `@unchecked Sendable` on a mock) and say which you dropped. One round,
then report; don't loop.

## 5. Report

Close with: the files added or changed, the UnitTests result, anything the reviewer raised that you dropped
and why, and any production-code problem you found but did not fix. Run `swiftlint` from the repo root and
report it. Never run the `AllTests` plan unless I ask for the UI tests. Don't commit.
