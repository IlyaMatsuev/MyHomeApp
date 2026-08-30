struct ScenarioTriggerLogic: Hashable {
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

    static let all = Self(mode: .all)
    static let any = Self(mode: .any)

    let mode: Mode
    let customExpression: String?

    init(mode: Mode, customExpression: String? = nil) {
        self.mode = mode
        self.customExpression = mode == .custom ? customExpression : nil
    }

    static func custom(_ expression: String) -> Self {
        Self(mode: .custom, customExpression: expression)
    }
}

extension ScenarioTriggerLogic {
    func expression(sourceCount: Int) -> String {
        switch mode {
        case .all: return Self.canonicalExpression(joinedBy: "AND", sourceCount: sourceCount)
        case .any: return Self.canonicalExpression(joinedBy: "OR", sourceCount: sourceCount)
        case .custom: return (customExpression ?? "").trimmed
        }
    }

    func isValid(sourceCount: Int) -> Bool {
        ScenarioLogicExpression.isValid(expression(sourceCount: sourceCount), sourceCount: sourceCount)
    }

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
