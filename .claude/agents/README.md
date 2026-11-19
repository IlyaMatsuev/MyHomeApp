# MyHomeApp Development Agents

This directory contains prompt configurations for AI agents that assist with development tasks for the My Home iOS app.

## Agents Overview

| Agent           | File             | Purpose                                             | Skills it invokes                                      |
| --------------- | ---------------- | --------------------------------------------------- | ------------------------------------------------------ |
| **Architect**   | `architect.md`   | Plans feature implementations, designs architecture | `ponytail`, `swift-architecture-skill`                 |
| **Implementer** | `implementer.md` | Writes Swift code following Architect's plans       | `ponytail`, `swiftui-pro`, `swift-concurrency-pro`     |
| **Reviewer**    | `reviewer.md`    | Reviews code for quality and standards              | `ponytail-review`, `swiftui-pro`, `swift-concurrency-pro` |
| **Tester**      | `tester.md`      | Writes Swift Testing unit tests and XCUITest UI tests | `ponytail`, `swift-concurrency-pro`                  |

Each agent file has a **Skills to use** section naming when to invoke which skill and which of its findings
to suppress. `swiftui-pro`, `swift-concurrency-pro` and `swift-architecture-skill` are vendored into
[.claude/skills/](../skills/); `ponytail` comes from the plugin enabled in
[.claude/settings.json](../settings.json). In every case the agent file and
[CLAUDE.md](../../CLAUDE.md) win on conflict — the skills are written for a generic project.

## Workflow

```
Feature Request
      │
      ▼
┌─────────────┐
│ Architect   │  ← Creates implementation plan (feature lane only)
└──────┬──────┘
       │ Plan
       ▼
┌──────────────┐
│ Implementer  │  ← Writes the code
└──────┬───────┘
       │ Code
       ▼
┌────────┐
│ Tester │  ← Writes tests, runs the UnitTests plan
└────┬───┘
     │ Code + tests
     ▼
┌──────────┐
│ Reviewer │  ← Checks quality & standards; reports, doesn't fix
└────┬─────┘
     │ Findings
     ▼
  back to Implementer, max 2 rounds, then hand what's left to the user
```

Tests come before review so the reviewer sees the tests as part of the diff, and so a problem the tests
expose (an untestable design, a missing protocol) is found before review rather than after.

`/work` drives this whole chain and picks which steps apply; `/test` runs just the Tester → Reviewer tail.

## Usage

### With Claude Code

Each file carries YAML frontmatter (`name`, `description`), so these are **real subagents**: Claude can
dispatch them by name, and will pick one on its own when a request matches its `description`. Ask for one
explicitly when you want to be sure:

```
Use the architect subagent to plan: "Add a device pairing flow"
```

```
Use the implementer subagent to implement task 3 from the plan
```

```
Use the reviewer subagent to review the changes in Screens/Devices/
```

None of them declares a `tools:` allowlist, so each inherits the full tool set — needed because every agent
invokes skills (see the table above). Architect's "writes no code" rule is enforced by its prompt, not by
tool scoping. Add `tools:` to an agent's frontmatter to restrict it, and `model:` to pin it to a specific
model; verify skills still load if you do.

`README.md` has no frontmatter, so it is not picked up as an agent.

### Agent Handoffs

Each agent produces artifacts the next agent consumes. Subagents start cold — they do **not** inherit the
dispatching conversation's context — so each handoff must be pasted into the dispatch prompt, not referred
to:

1. **Architect → Implementer**
    - Implementation plan with tasks, in full
    - View / ViewModel / Model interfaces
    - File paths and folder structure

2. **Implementer → Tester**
    - Completed source code; the changed-file list (`git diff --name-only`)
    - What behaviour changed; for a bug fix, the bug itself so the test would have caught it

3. **Tester → Reviewer**
    - The diff (`git diff`), production code and tests together
    - The original request, so the reviewer can judge scope creep

4. **Reviewer → Implementer** (if issues found)
    - Review comments, triaged — findings that contradict CLAUDE.md are dropped first
    - Required fixes, with the reviewer's reasoning attached
    - Max 2 rounds, then whatever is still open goes to the user

## Quick Reference

### Architect Outputs

- Implementation plan markdown
- Task breakdown with dependencies
- View / ViewModel / Model contracts
- Navigation flow

### Implementer Outputs

- Swift source files (`.swift`)
- SwiftUI views, ViewModels, models
- Service / repository layers
- Asset and color set additions

### Reviewer Outputs

- Review summary (Approve / Request Changes)
- Issue list with fixes
- Code suggestions

### Tester Outputs

- `*Tests.swift` files — Swift Testing for unit tests, XCTest for UI tests
- Mock / stub helpers
- UI tests where appropriate
