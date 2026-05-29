---
description: Write/adjust XCTest unit tests for my recent code changes following the Tester workflow
---

I've just updated some code. Write unit tests for the new code, or adjust the existing tests if needed.

Rules:

- Do NOT change my newly written (non-test) code. Only add or modify test files. If something requires changes to write proper unit tests (e.g. a service is not exposed via a protocol), ask first.
- Validate my changes first: read the diff, confirm the code is correct, and flag anything that looks wrong before writing tests.
- Follow the Tester workflow defined in `.claude/agents/tester.md` (XCTest, `<Type>Tests.swift` under `SmartHomeAppIOSTests/`, `@MainActor` test classes for `@MainActor` view models, hand-rolled protocol mocks, fixtures via `Type.fixture(...)` extensions).
- Match the existing test style and structure in the affected test files.
- When the implementation moved/renamed things, move/rename the corresponding tests the same way rather than duplicating.
- Run the affected tests (and then the full suite) via `xcodebuild test -scheme SmartHomeAppIOS -destination 'platform=iOS Simulator,name=iPhone 16'` to confirm everything is green before reporting.

Scope: $ARGUMENTS

If no scope is given above, default to the changes in the last commit plus any uncommitted working-tree changes (`git show HEAD` and `git diff`).
