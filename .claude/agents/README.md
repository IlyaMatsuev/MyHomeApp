# MyHomeApp Development Agents

Four subagents, dispatchable by name (each file carries `name` / `description` frontmatter, so Claude can
also pick one on its own when a request matches). `README.md` has no frontmatter, so it isn't an agent.

| Agent | File | Does | Skills it invokes |
| --- | --- | --- | --- |
| **Architect** | `architect.md` | Plans a feature; writes no code | `ponytail`, `swift-architecture-skill` |
| **Implementer** | `implementer.md` | Writes the Swift | `ponytail`, `swiftui-pro`, `swift-concurrency-pro` |
| **Tester** | `tester.md` | Writes Swift Testing / XCUITest tests | `ponytail`, `swift-concurrency-pro` |
| **Reviewer** | `reviewer.md` | Reports findings; doesn't fix | `ponytail-review`, `swiftui-pro`, `swift-concurrency-pro` |

The chain is **Architect → Implementer → Tester → Reviewer**, looping back to Implementer for at most two
rounds, then whatever is still open goes to the user. Tests come before review so the reviewer sees them as
part of the diff, and so a problem the tests expose — an untestable design, a missing protocol — surfaces
before review rather than after.

`/work` drives the chain and picks which steps apply (a typo fix gets no architecture plan);
[/work §2](../commands/work.md) is the authority on the handoff contracts, because subagents start cold and
every dispatch prompt has to carry what the next agent needs. `/test` runs just the Tester → Reviewer tail.

## Where the rules live

[CLAUDE.md](../../CLAUDE.md) owns the toolchain, project structure, architecture, coding rules, test
conventions, the build/lint gate and the skill-conflict resolutions. The agent files add role-specific
workflow on top and link back for the rest — so a rule has one home and can't drift between copies.
[implementer.md](implementer.md#project-patterns) is the exception worth knowing about: it holds the
patterns as working code, and the other files point at it.

Skills: `swiftui-pro`, `swift-concurrency-pro` and `swift-architecture-skill` are vendored in
[.claude/skills/](../skills/); `ponytail` comes from the plugin in [settings.json](../settings.json).

## Notes

No agent declares a `tools:` allowlist, so each inherits the full tool set — needed because they all invoke
skills. Architect's "writes no code" rule is enforced by its prompt, not by tool scoping. Add `tools:` to
restrict one, or `model:` to pin it, and verify skills still load if you do.
