# Feature: Scenarios Tab

## Overview

Add a fully functional **Scenarios** tab that lets the user browse, create, edit, enable/disable and delete
scenarios — the hub entity that describes *"when X happens, do Y"*. The screen mirrors the existing Devices
tab (grouped list, chip filter bar, server switcher, toast-based error reporting) so the app keeps a single
visual and architectural language.

The scenario domain is considerably richer than the device domain: a scenario owns a **trigger** (a list of
heterogeneous sources plus a boolean expression that combines them) and a list of **actions** (device control
values to set). The plan below models that faithfully, but keeps the editor UI constrained to the subset the
app can express safely today.

## Requirements

- [x] The Scenarios tab is reachable from the root `TabView` (today `ScenariosView` exists as a placeholder and is not wired up).
- [x] The user can see all existing scenarios, grouped by their `group` field, filterable by group.
- [x] The user can enable/disable a scenario inline (the `active` flag) without opening an editor.
- [x] The user can create a new scenario.
- [x] The user can update an existing scenario.
- [x] The user can delete a scenario, with a confirmation step.
- [x] Trigger sources of both supported kinds (`cron`, `device`) can be added, edited and removed.
- [x] The `trigger.logic` expression is manageable without hand-writing a boolean string in the common case.
- [x] Errors surface through the existing `ToastStore`; the list keeps working when a single action fails.

## Affected Screens / Folders

| Area                        | Changes                                                                     |
| --------------------------- | --------------------------------------------------------------------------- |
| `Core/Scenarios`            | **New.** Domain models, `ScenarioService` protocol, hub + mock implementations, environment key |
| `Screens/Scenarios`         | Replace the placeholder with the list screen, view model, editor sheets and draft models |
| `Shared/Components`         | Extract the chip filter bar used by both Devices and Scenarios              |
| `Screens/Devices`           | `DeviceRoomFilterList` becomes a thin adapter over the shared chip bar (no behaviour change) |
| `ContentView.swift`         | Add the Scenarios tab                                                        |
| `MyHomeApp.swift`           | Construct and inject `HubScenarioService`                                    |
| `MyHomeAppTests`            | Fixtures, stub service and unit tests for the new models / view models       |

## API contract

The hub is the source of truth: `smarthome/src/scenarios` (controller, DTOs, mongoose schemas and
validators) plus the Postman collection in `smarthome/api`. A `Scenarios.ScenarioResponse` looks like:

```json
{
  "externalId": "d3ccf155-3ed5-459c-aec2-f37f6402f1a1",
  "name": "Warm light on",
  "description": "Switches on the warm light in the living room",
  "group": "living_room",
  "active": true,
  "trigger": {
    "sources": [
      { "type": "cron", "cron": "8 21 * * *", "adjustTo": "sunset" },
      { "type": "device", "device": { "externalId": "...", "commands": { "are": { "action": "up_press" } } } },
      { "type": "device", "device": { "externalId": "...", "controls": { "are": { "on": false } } } }
    ],
    "logic": "(1 OR 2) AND 3"
  },
  "actions": [ { "externalId": "...", "set": { "controls": { "on": true } } } ],
  "repeatTimes": 3,
  "createdAt": "2025-08-30T16:04:38.229Z",
  "updatedAt": "2026-08-15T10:52:37.396Z"
}
```

Shape quirks the decoder must absorb:

1. A `cron` source carries its payload **flat** (`cron`, `adjustTo` next to `type`), while a `device` source
   nests it under a `device` key. → custom `Codable` on the source enum.
2. `group` uses `snake_case` (`living_room`) while `Device.room` uses `kebab-case` (`living-room`). They are
   *different* vocabularies, and the hub creates a group on demand from whatever a scenario names. → `group`
   is a plain `String?`; **absent means no group**, and there is no `"none"` group as there is for rooms.
   `ScenarioGroupName` holds the display wording and the hub's naming rule.
3. A device trigger source and an action `set` are each keyed by device *config section* — the hub's
   `commands` / `controls` / `measurements`. All three decode, so editing a scenario created elsewhere
   cannot silently drop a section.

Endpoints:

| Operation      | Request                                     |
| -------------- | ------------------------------------------- |
| List           | `GET /scenarios?pageSize=20&includeInactive=true` — **the hub filters inactive scenarios out by default**, and the list needs them for their toggle |
| Create         | `POST /scenarios` with the full payload     |
| Update         | `PUT /scenarios/{externalId}`; every field is optional and the hub merges field by field (`dto.x ?? stored.x`) |
| Toggle active  | `PUT /scenarios/{externalId}` with `{ "active": Bool }` |
| Delete         | `DELETE /scenarios/{externalId}`            |

Not used by the app today: `GET/POST/DELETE /scenarios/groups[/{name}]` (a group resource carrying a
`scenariosCount`) and the `group` / `room` list filters. The screen derives its group chips from the
loaded scenarios instead, so a chip can never select an empty list.

Two consequences of the merge semantics worth knowing: a `nil` in `ScenarioPayload` is omitted rather
than sent as `null`, so **the editor cannot clear a description or a group** once set — only the hub can;
and `repeatTimes` is read-only here, preserved by being left out of every update.

### Validation the client mirrors

`ScenarioLimits` and `ScenarioGroupName` copy the hub's constraints so a save that the hub will reject is
blocked in the form instead: name 3–80, description 10–255 (or absent), group 3–40 matching
`[A-Za-z0-9_]+` and never digits only, `logic` 1–80, and **at most one `cron` source per scenario**.

## New Files

**Core**

- `Core/Scenarios/Models/Scenario.swift` — the API entity.
- `Core/Scenarios/Models/ScenarioAction.swift` — `ScenarioAction` + `ScenarioActionSet`.
- `Core/Scenarios/Models/ScenarioTrigger.swift` — `sources` + raw `logic` string.
- `Core/Scenarios/Models/ScenarioTriggerSource.swift` — the source enum with custom `Codable`, plus
  `ScenarioCronTrigger`, `ScenarioDeviceTrigger`, `ScenarioValueMatch`.
- `Core/Scenarios/Models/ScenarioSolarAdjustment.swift` — `sunrise` / `sunset`.
- `Core/Scenarios/Models/ScenarioGroupName.swift` — display wording for a `group` + the hub's naming rule.
- `Core/Scenarios/Models/ScenarioGroupFilter.swift` — `all` / `ungrouped` / `named`.
- `Core/Scenarios/Models/ScenarioLimits.swift` — the hub's field constraints, mirrored.
- `Core/Scenarios/Models/ScenarioTriggerLogic.swift` — `Mode` (`all` / `any` / `custom`) + custom expression string bridging.
- `Core/Scenarios/Models/ScenarioLogicExpression.swift` — validator for custom expressions.
- `Core/Scenarios/Models/ScenarioPayload.swift` — the writable subset sent to the hub.
- `Core/Scenarios/Models/ScenarioError.swift` — user-facing wording for `HubAPIError`, shared by list and editor.
- `Core/Scenarios/ScenarioService.swift`, `HubScenarioService.swift`, `MockScenarioService.swift`,
  `EnvironmentValues+ScenarioService.swift`.

**Screens**

- `Screens/Scenarios/ScenariosViewModel.swift` — list state, filtering, active toggle, deletion, editor presentation.
- `Screens/Scenarios/ScenarioList.swift`, `ScenarioListRow.swift`.
- `Screens/Scenarios/ScenarioEditorViewModel.swift` — one editor session (create or edit).
- `Screens/Scenarios/ScenarioEditorSheet.swift` — the form.
- `Screens/Scenarios/ScenarioSourceCard.swift`, `ScenarioActionCard.swift` — a trigger source / an action, edited
  inline in the form rather than in a nested sheet (one less level of modality for a handful of fields).
- `Screens/Scenarios/ScenarioDevicePicker.swift` — the device menu shared by both cards.
- `Screens/Scenarios/ScenarioDraft.swift`, `ScenarioSourceDraft.swift`, `ScenarioActionDraft.swift` — UI-side
  draft models, one type per file per the project's file-naming rule.

**Shared**

- `Shared/Components/FilterChipsBar.swift` — the horizontal selectable chip row.
- `Shared/Components/FormTextField.swift` — the labelled text field the editor's fields are built from.
- `Shared/Extensions/String+Trimmed.swift` — `trimmed` / `isBlank`, used across the draft validation.

## Model / ViewModel Contracts

```swift
struct Scenario: Codable, Identifiable, Hashable {
    let externalId: String
    let name: String
    let description: String?
    let trigger: ScenarioTrigger
    let actions: [ScenarioAction]
    var active: Bool
    let group: String?              // nil == no group
    let repeatTimes: Int?           // read-only here; the hub counts it down
    let createdAt: Date
    let updatedAt: Date

    var id: String { externalId }
}

enum ScenarioTriggerSource: Codable, Hashable {
    case cron(ScenarioCronTrigger)
    case device(ScenarioDeviceTrigger)
}

protocol ScenarioService: Sendable {
    func fetchScenarios() async throws -> Page<Scenario>
    func createScenario(payload: ScenarioPayload) async throws -> Scenario
    func updateScenario(scenarioId: String, payload: ScenarioPayload) async throws -> Scenario
    func setActive(scenarioId: String, active: Bool) async throws -> Scenario
    func deleteScenario(scenarioId: String) async throws
}

@Observable @MainActor
final class ScenariosViewModel {
    enum LoadState: Equatable { case idle, loading, loaded, failed(String) }

    var selectedGroup: ScenarioGroupFilter
    private(set) var state: LoadState
    var groupSections: [ScenarioGroupSection]   // keyed by the optional group
    private(set) var devices: [Device]          // for editor pickers; best-effort
    var editor: ScenarioEditorViewModel?        // drives .sheet(item:)
    var scenarioPendingDeletion: Scenario?      // drives .confirmationDialog
}
```

### Why a separate draft model

`Scenario` is immutable (`let` everywhere) and shaped by the wire format — an enum with associated values for
sources, dictionaries of `AnyCodable` for match values. That is a poor fit for SwiftUI two-way bindings, and
list identity would be ambiguous (two actions may target the same device, so `externalId` is not a stable id).

The editor therefore works on `ScenarioDraft`, whose rows carry a `UUID` id and whose fields are flat and
directly bindable. `ScenarioDraft.init(scenario:)` and `ScenarioDraft.payload` bridge the two. This keeps
`ForEach` identity correct across insert/delete and keeps SwiftUI out of the wire model.

## Trigger logic — UX and a suggested API change

### The problem with `logic: "(1 OR 2) AND 3"`

The expression references sources by **1-based position**. Deleting or reordering a source silently changes
the meaning of the expression: remove source 1 and `"(1 OR 2) AND 3"` now points at the wrong operands, or at
an index that no longer exists. It also forces every client to ship a parser to do anything smarter than
showing the raw string.

### Recommendation for the hub API (not implemented client-side — it needs a hub change)

Give each source a stable `id` and replace the expression string with a small recursive node:

```json
"trigger": {
  "sources": [
    { "id": "evening",  "type": "cron",   "cron": "8 21 * * *", "adjustTo": "sunset" },
    { "id": "remote",   "type": "device", "device": { ... } },
    { "id": "lightOff", "type": "device", "device": { ... } }
  ],
  "match": { "all": [ { "any": ["evening", "remote"] }, "lightOff" ] }
}
```

Grammar: a node is either a source id (string), `{"all": [node...]}`, `{"any": [node...]}`, or `{"not": node}`.

Why it is better:

- **Reorder- and delete-safe** — references are ids, not positions.
- **No parser anywhere** — it is already a tree; every client and the hub itself just walk it.
- **Directly renderable** — the UI nesting maps 1:1 onto the JSON nesting.
- **Trivially validated** — "every referenced id exists" is the whole validation.
- **Backwards compatible** — the hub can keep accepting `logic` and treat `match` as the preferred field when present.

### What this app ships now (against today's string API)

The hub's own grammar is narrower than it looks: `validateTriggerLogic` accepts digits joined by `AND`
and `OR` with decorative parentheses, has **no `NOT`**, and requires the operands to reference every
source exactly once. `ScenarioLogicExpression` implements exactly that rule and nothing more.

Almost every real scenario is "all of these" or "any of these". So the editor offers a three-way choice:

| Choice                  | Serialised `logic`      |
| ----------------------- | ----------------------- |
| **All must match**      | `1 AND 2 AND 3`         |
| **Any can match**       | `1 OR 2 OR 3`           |
| **Custom expression**   | verbatim user input     |

On load the string is parsed back: if it is exactly the canonical all-`AND` / all-`OR` form for the current
source count it is shown as *All* / *Any*, otherwise as *Custom* with the original text preserved. Custom
input is validated client-side by a small recursive-descent parser (`ScenarioLogicExpression`) over the
input is validated client-side against the hub's rule, which also rejects indexes outside
`1...sources.count`. Saving is blocked while the expression is invalid, so the positional footgun can no
longer produce a scenario the hub will reject.

## Navigation / UX

```
TabView
└── Scenarios (NavigationStack)
    ├── toolbar: ServerSwitcherMenu (trailing), "+" add button (trailing)
    ├── FilterChipsBar — All | <group> | <group> ...
    └── List, sectioned by group
        └── row: name · trigger/action summary · active Toggle
            ├── tap        → editor sheet (edit)
            └── swipe left → Delete → confirmationDialog
```

- The **editor sheet** is a `Form`-less `ScrollView` styled like `AddEditServerSheet` (Cancel / Save toolbar):
  name, description, group, active, *When* (trigger sources + match mode), *Then* (device actions).
- **Trigger sources** are numbered cards edited inline. Adding uses a menu ("On a schedule" / "When a device...");
  the card's number is the index a custom logic expression refers to.
- **Device sources** pick a device from the loaded device list, then match one of the hub's three
  condition sections: a *command* (free text, e.g. `up_press` — commands are not discoverable from
  `Device`), a *control* (picker over the device's boolean control keys + a toggle) or a *measurement*
  (picker over the device's measurement keys + the value to equal).
- **Actions** are edited inline: device picker + control key picker + on/off toggle. This matches the only
  control shape the app models today (`DeviceControlType.toggle`).
- The logic picker appears once there is more than one source — **or** whenever the mode is `Custom`, so that
  deleting sources can never strand an expression that blocks saving with no control left to fix it.
- Scenarios whose stored trigger uses a shape the editor cannot express are still listed, toggled and deleted
  normally; the editor surfaces the parts it understands and leaves `Custom` logic untouched.

## Networking / Persistence Changes

- New `HubScenarioService` on top of the existing `MyHomeAPIClient`; no changes to `HubAPIClient`,
  auth, or persistence. Nothing about scenarios is cached locally.
- `ScenarioPayload` is `Encodable` only and contains no dates, so the default `JSONEncoder` is sufficient
  (there is no `JSONEncoder.hubAPI` counterpart today and this feature does not need one).

## Implementation Tasks

1. [x] **Domain models** (Size: M) — `Core/Scenarios/Models/*`. Faithful `Codable` for the issue's JSON.
2. [x] **Logic model + validator** (Size: M) — `ScenarioTriggerLogic`, `ScenarioLogicExpression`. Depends on 1.
3. [x] **Service layer** (Size: S) — protocol, hub implementation, mock, environment key. Depends on 1.
4. [x] **Shared chip bar** (Size: S) — `FilterChipsBar`; re-point `DeviceRoomFilterList` at it.
5. [x] **List screen** (Size: M) — `ScenariosViewModel`, `ScenariosView`, `ScenarioList`, `ScenarioListRow`,
      and the group chip bar. Depends on 3, 4.
6. [x] **Draft models** (Size: M) — `ScenarioDraft` + bridging to/from `Scenario` / `ScenarioPayload`. Depends on 1, 2.
7. [x] **Editor** (Size: L) — `ScenarioEditorViewModel`, `ScenarioEditorSheet`, `ScenarioSourceCard`,
      `ScenarioActionCard`. Depends on 5, 6.
8. [x] **Tab wiring** (Size: S) — `ContentView`, `MyHomeApp`. Depends on 5.
9. [x] **Tests** (Size: L) — see below. Depends on 1–8.

## Testing Requirements

Unit tests (Swift Testing, `UnitTests` plan):

- `ScenarioCodableTests` — decodes the issue's JSON **verbatim**; round-trips; tolerates a missing
  `group` / `description` / `logic` and an unknown group value.
- `ScenarioGroupNameTests` — label humanisation (`living_room` → `Living Room`), the `Ungrouped` fallback, the hub's name rule.
- `ScenarioTriggerLogicTests` — canonical `AND`/`OR` generation, parse-back, custom preservation.
- `ScenarioLogicExpressionTests` — the hub's grammar exactly: no `NOT`, every source referenced once, out-of-range indexes.
- `HubScenarioServiceTests` — request shape (method, path, query incl. `includeInactive`, body) and error propagation for all five operations.
- `ScenariosViewModelTests` — load/group/sort/filter, active toggle incl. rollback on failure, deletion, editor presentation.
- `ScenarioEditorViewModelTests` — validation gating, create vs update call, payload contents, failure handling.
- `ScenarioDraftTests` / `ScenarioDraftValidationTests` — `Scenario` → draft → payload fidelity, and the mirrored hub limits.

New mocks: `MyHomeAppTests/Mocks/Scenario+Fixture.swift` (fluent builder, like `Device+Fixture`) and
`MyHomeAppTests/Mocks/StubScenarioService.swift`.

No UI tests — the existing suite has none for Devices either.

## Documentation Needs

- `CLAUDE.md`: note the new `Core/Scenarios` area and the draft-model convention for form-heavy editors.
- This plan documents the suggested `trigger.match` API change for the hub side.

## Risks & Mitigations

| Risk                                                                 | Mitigation                                                                                          |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| ~~Scenario endpoints are inferred from the device endpoints~~          | Resolved: every shape here is checked against the hub source and pinned by tests |
| Unknown `group` values from the hub break the list                    | `group` is a plain `String?`, not an enum; unknown values render humanised                           |
| Hub adds a third trigger source `type`                                | Decoding a scenario with an unknown source type fails loudly rather than silently dropping the source; the enum is the single place to extend |
| Positional `logic` breaks when sources are reordered                  | Editor writes canonical expressions for All/Any and validates custom ones against the source count   |
| Editor cannot express every possible stored trigger                   | Non-expressible scenarios stay listable/toggleable/deletable; `Custom` logic text is preserved verbatim |
| `ScenarioDraft` is a wide struct                                      | Deliberate — flat fields are what SwiftUI bindings need; conversion is centralised and unit-tested   |
