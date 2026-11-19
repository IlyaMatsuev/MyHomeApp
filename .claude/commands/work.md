---
description: Develop a feature or fix a bug end to end through the Architect → Implementer → Tester → Reviewer workflow
argument-hint: <what to build or fix>
---

Take the request below through this project's development workflow.

**Request:** $ARGUMENTS

If the request above is empty, ask what to work on and stop.

## 1. Triage first — pick a lane, don't run all five agents by reflex

Read the request and enough of the code it touches to size it. Then say in one line which lane you picked
and why, and follow it. Scaling the workflow to the work is the point; a typo fix does not need an
architecture plan.

| Lane | When | Steps |
| --- | --- | --- |
| **Trivial** | One-line fix, copy/colour change, lint fix, renaming one symbol. No behaviour change worth testing. | Do it yourself. Build + `swiftlint`. Report. No subagents. |
| **Bug fix** | Wrong behaviour in existing code, no new screen / service / store. | `implementer` → `tester` → `reviewer` |
| **Feature** | New screen, service, store, model, or a change that adds a flow. | `architect` → `implementer` → `tester` → `reviewer` |

When it sits between two lanes, take the smaller one and say so — it is cheaper to escalate than to unwind
an over-planned change.

## 2. Dispatch rules

Subagents do **not** share your context. Each one starts cold, so every dispatch prompt must carry what
that agent needs. Pass it explicitly:

- **→ `architect`**: the request verbatim, plus the files and screens you found that it touches.
- **→ `implementer`**: the approved plan *in full* (paste the text — do not reference "the plan above"),
  the task to implement, and the exact file paths.
- **→ `tester`**: the list of files changed (`git diff --name-only`) and what behaviour changed. For a bug
  fix, state the bug so the test would have caught it.
- **→ `reviewer`**: the diff (`git diff`), plus the original request so it can judge scope creep.

Run straight through without stopping between agents. Show me the plan when `architect` produces one, then
keep going — don't wait for approval. I'll interrupt if I want to change course.

## 3. The review loop — bounded at 2 rounds

`reviewer` reports findings; it does not fix them. For each round:

1. Triage the findings yourself. Drop ones that contradict CLAUDE.md (iOS 27+ / Swift 6 suggestions,
   `#available` checks, `ObservableObject`, "ask before adding a library", or flagging an established
   project pattern as over-engineering).
2. Send the ones that stand to `implementer` as a fix list, with the reviewer's reasoning attached.
3. Re-review **only the new diff**.

After two rounds, stop looping. Report whatever is still open and let me decide. Do not keep cycling.

## 4. Gates

- **Plan stays in the conversation.** Show the `architect` plan inline; don't write a plan file unless I
  ask for one.
- **Build gate.** Before reporting done, run both and report the real result:
  - `xcodebuild build -scheme MyHomeApp -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=26.5'`
  - `swiftlint` from the repo root
  Never claim success without a green run. If you cannot run a step, say so explicitly.
- **Test gate.** Run the **UnitTests** plan. Never the `AllTests` plan unless I ask for the UI tests.
- **No commits.** Leave everything in the working tree and tell me what changed. I commit.

## 5. Report

Close with: the lane you took, what changed (file list), build / lint / test results, anything the reviewer
raised that you dropped and why, and anything you deliberately left out of scope.
