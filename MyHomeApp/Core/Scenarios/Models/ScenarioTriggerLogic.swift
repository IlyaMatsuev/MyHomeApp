/// How the trigger sources combine.
///
/// The hub stores a positional boolean string (`"(1 OR 2) AND 3"`). Almost every real scenario is
/// "all of these" or "any of these", so the app models those two explicitly and keeps a `custom`
/// escape hatch for anything else.
enum ScenarioTriggerLogic: Hashable {
    case all
    case any
    case custom(String)

    enum Mode: String, Hashable, CaseIterable, Identifiable {
        case all
        case any
        case custom

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all: return "All must match"
            case .any: return "Any can match"
            case .custom: return "Custom"
            }
        }
    }

    var mode: Mode {
        switch self {
        case .all: return .all
        case .any: return .any
        case .custom: return .custom
        }
    }

    var customExpression: String? {
        switch self {
        case .custom(let expression): return expression
        case .all, .any: return nil
        }
    }
}

extension ScenarioTriggerLogic {
    /// The expression to send to the hub for a trigger with `sourceCount` sources.
    func expression(sourceCount: Int) -> String {
        switch self {
        case .all: return Self.canonicalExpression(joinedBy: "AND", sourceCount: sourceCount)
        case .any: return Self.canonicalExpression(joinedBy: "OR", sourceCount: sourceCount)
        case .custom(let expression): return expression.trimmed
        }
    }

    func isValid(sourceCount: Int) -> Bool {
        ScenarioLogicExpression.isValid(expression(sourceCount: sourceCount), sourceCount: sourceCount)
    }

    /// Maps a stored expression back onto the editor's three-way choice.
    ///
    /// An expression that is exactly the canonical all-`AND` / all-`OR` form for the current source
    /// count round-trips as `.all` / `.any`; anything else is preserved verbatim as `.custom`.
    static func parse(_ expression: String, sourceCount: Int) -> Self {
        guard !expression.isBlank else { return .all }

        let normalized = normalize(expression)
        if normalized == normalize(canonicalExpression(joinedBy: "AND", sourceCount: sourceCount)) {
            return .all
        }
        if normalized == normalize(canonicalExpression(joinedBy: "OR", sourceCount: sourceCount)) {
            return .any
        }
        return .custom(expression)
    }

    private static func canonicalExpression(joinedBy operatorName: String, sourceCount: Int) -> String {
        guard sourceCount > 0 else { return "" }
        return (1...sourceCount)
            .map { "\($0)" }
            .joined(separator: " \(operatorName) ")
    }

    private static func normalize(_ expression: String) -> String {
        expression
            .uppercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
