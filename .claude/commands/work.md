---
description: Develop a feature or fix a bug end to end — requirements, plan, code, tests, then an independent review
argument-hint: <what to build or fix>
---

Take the request below through this project's development workflow. You do the planning, coding and testing
yourself, in this conversation; the only subagent is `reviewer`.

**Request:** $ARGUMENTS

If the request above is empty, ask what to work on and stop.

## 1. Understand first — and ask

Follow [CLAUDE.md § Before you change anything](../../CLAUDE.md#before-you-change-anything). Concretely,
before triaging or editing:

1. Read the request and trace the code it touches. For a bug, establish the root cause.
2. State the problem and the requirements as you understand them, in a few lines: expected behaviour, what
   is in and out of scope, assumptions you are making.
3. If anything is open, ask me — all questions at once, each with your recommended answer — and **stop until
   I reply**. If nothing is open, say so and continue without waiting.

This applies to every lane. A genuinely clear one-line fix simply has no questions.

## 2. Triage — pick a lane

Say in one line which lane you picked and why, and follow it.

| Lane | When | Steps |
| --- | --- | --- |
| **Trivial** | One-line fix, copy/colour change, lint fix, renaming one symbol. No behaviour change worth testing. | Code → gates |
| **Small fix** | Wrong behaviour with a contained fix: one or two production files, no new type, no change to auth, persistence, networking or concurrency. | Code → tests → gates |
| **Full** | Everything else: new screen / service / store / model / flow, or a fix too wide or risky for the row above. | Plan → code → tests → gates → review |

Between two lanes, take the smaller one and say so; escalate if it grows. I can ask for a review, or for a
lane, in any request.

## 3. Worktree

Enter a worktree before the first edit, unless I asked you not to —
[CLAUDE.md § Worktrees](../../CLAUDE.md#worktrees) has the rules and the exceptions.

## 4. Build it

Read each guide when you reach its step, not before, and only for the steps your lane has. Once §1 is
settled, run straight through without waiting for approval; stop only for a new question that is mine to
answer.

1. **Plan** — [guides/planning.md](../guides/planning.md). Show it inline, then keep going. Don't write a
   plan file unless I ask for one.
2. **Code** — [guides/implementing.md](../guides/implementing.md). Trivial lane: skim the nearest code
   instead.
3. **Tests** — [guides/testing.md](../guides/testing.md). For a bug fix, the test must be one the bug would
   have failed.

Keep the loop short. While iterating, run only the tests you touched (`-only-testing:`). Don't write
throwaway spikes or drive the simulator by default: do it once, for a UI change you can't judge from the
code or a platform behaviour the plan depends on and you're genuinely unsure of.

## 5. Gates

Run these once, on the finished code, and report the real result. Never claim success without a green run;
if you cannot run a step, say so explicitly.

- The build and `swiftlint` from [CLAUDE.md § Build & test](../../CLAUDE.md#build--test).
- The whole **UnitTests** plan, except in the trivial lane. Never `AllTests` unless I ask for the UI tests.

## 6. Review — full lane only, or when I ask

Dispatch `reviewer` once. It starts cold on purpose, so the prompt carries what it needs: the absolute path
to work in, the original request, the settled requirements with my answers, the plan, how to get the diff
(`git diff` plus the untracked files by name), and the gate results so it doesn't rerun them. Don't argue
for the implementation in the prompt; that defeats the fresh eyes.

Then triage the findings yourself. Drop ones that contradict
[CLAUDE.md § Skill conflicts](../../CLAUDE.md#skill-conflicts--resolved-once-here) and ones that flag an
established project pattern as over-engineering. Fix what stands, and rerun §5 if you changed code.

Re-review **only if a Critical finding was fixed**, and then only that new diff. Two rounds at most; report
whatever is still open and let me decide.

## 7. Report

Close with: the lane, the worktree path and branch, what changed (file list), build / lint / test results,
review findings you dropped and why, and anything you deliberately left out of scope.

**No commits.** Leave everything uncommitted in the worktree. I commit.
