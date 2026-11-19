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

Then read the actual change before dispatching anything, and state in one line what you resolved the scope
to and which files it covers. Derive that file list from the resolved scope — for the empty-scope default
that's `git diff --name-only HEAD~1` (last commit through the working tree), but for an explicit scope it's
whatever files that scope names.

## 2. Dispatch `tester`

Pass it: the resolved scope, the file list, and what behaviour changed. Tell it to:

- **Validate the production code first.** Read the diff and confirm the code is correct before writing
  tests. Flag anything that looks wrong in the final report.
- **Not pause for confirmation before writing the tests.** Make a reasonable judgment call and proceed.
- **Not change production code.** Only add or modify files under `MyHomeAppTests/`. The one case to stop
  and ask about is a test that genuinely cannot be written without a production change (e.g. a service
  isn't behind a protocol) — ask rather than reshaping production code to suit a test.
- **Match the existing test style and structure** in the affected test files, and follow the Tester
  workflow in [../agents/tester.md](../agents/tester.md).
- **Keep XCTest out of the unit target.** New unit tests are Swift Testing; `MyHomeAppUITests/` stays
  XCTest.
- Move or rename tests alongside anything the implementation moved or renamed, instead of duplicating.
- Run the affected tests, then the whole unit suite, via the **UnitTests** plan and confirm green before
  reporting.

## 3. Dispatch `reviewer` — scoped to the tests

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

Fix what stands — test-side fixes only. Drop findings that contradict this project's conventions (Swift 6
constructs, `#available`, XCTest style in the unit target) and say which you dropped. One round, then
report; don't loop.

## 5. Report

Close with: the files added or changed, the UnitTests result, anything the reviewer raised that you dropped
and why, and any production-code problem you found but did not fix. Run `swiftlint` from the repo root and
report it. Never run the `AllTests` plan unless I ask for the UI tests. Don't commit.
