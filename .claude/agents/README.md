# SmartHomeAppIOS Development Agents

This directory contains prompt configurations for AI agents that assist with development tasks for the SmartHome iOS app.

## Agents Overview

| Agent           | File             | Purpose                                             |
| --------------- | ---------------- | --------------------------------------------------- |
| **Architect**   | `architect.md`   | Plans feature implementations, designs architecture |
| **Implementer** | `implementer.md` | Writes Swift code following Architect's plans       |
| **Reviewer**    | `reviewer.md`    | Reviews code for quality and standards              |
| **Tester**      | `tester.md`      | Writes XCTest unit and UI tests                     |
| **StoryTeller** | `storyteller.md` | Creates documentation                               |

## Workflow

```
Feature Request
      │
      ▼
┌─────────────┐
│ Architect   │  ← Creates implementation plan
└──────┬──────┘
       │ Plan
       ▼
┌──────────────┐
│ Implementer  │  ← Writes the code
└──────┬───────┘
       │ Code
       ▼
┌──────────┐
│ Reviewer │  ← Checks quality & standards
└────┬─────┘
     │ Approved
     ▼
┌────────┐
│ Tester │  ← Writes tests
└────┬───┘
     │ Tests pass
     ▼
┌─────────────┐
│ StoryTeller │  ← Documents the feature
└─────────────┘
```

## Usage

### With Claude Code

Reference an agent's prompt when starting a task:

```
Use the Architect agent to plan: "Add a device pairing flow"
```

```
Use the Implementer agent to implement task 3 from the plan
```

```
Use the Reviewer agent to review the changes in Screens/Devices/
```

### Agent Handoffs

Each agent produces artifacts the next agent consumes:

1. **Architect → Implementer**
    - Implementation plan with tasks
    - View / ViewModel / Model interfaces
    - File paths and folder structure

2. **Implementer → Reviewer**
    - Swift source files
    - View, ViewModel, Service changes

3. **Reviewer → Implementer** (if issues found)
    - Review comments
    - Required fixes

4. **Implementer → Tester**
    - Completed source code
    - ViewModels / services to test

5. **Tester → StoryTeller**
    - Test coverage report
    - Behavior documentation

6. **All Agents → StoryTeller**
    - Architecture decisions (from Architect)
    - Public API surface (from Implementer)
    - Usage examples (from Tester)

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

- `*Tests.swift` (XCTest) files
- Mock / stub helpers
- UI tests where appropriate

### StoryTeller Outputs

- DocC comments on public API
- README sections
- Architecture / configuration docs
