/// Validator for the hub's positional trigger expressions, e.g. `"(1 OR 2) AND 3"`.
///
/// Mirrors `validateTriggerLogic` on the hub: operands are 1-based positions in `trigger.sources`
/// joined by `AND` / `OR`, parentheses are decorative, and every source must be referenced exactly
/// once. Notably the hub supports **no** `NOT` — accepting one here would only produce a 400.
enum ScenarioLogicExpression {
    /// `true` when `expression` is one the hub will accept for a trigger with `sourceCount` sources.
    static func isValid(_ expression: String, sourceCount: Int) -> Bool {
        guard sourceCount > 0, ScenarioLimits.logicLength.contains(expression.count) else { return false }
        guard let operands = operands(in: expression) else { return false }
        return operands.count == sourceCount && operands.allSatisfy { (1...sourceCount).contains($0) }
    }

    /// The 1-based positions the expression references, or `nil` when it is malformed.
    private static func operands(in expression: String) -> [Int]? {
        let text = expression.uppercased()
        var operands: [Int] = []
        var index = text.startIndex

        func skip(while predicate: (Character) -> Bool) {
            while index < text.endIndex, predicate(text[index]) {
                index = text.index(after: index)
            }
        }

        while true {
            skip { $0 == " " || $0 == "(" }

            let digitsStart = index
            skip { $0.isASCII && $0.isNumber }
            guard digitsStart < index, let operand = Int(text[digitsStart..<index]) else { return nil }
            operands.append(operand)

            skip { $0 == " " || $0 == ")" }

            guard index < text.endIndex else { return operands }

            if text[index...].hasPrefix("AND") {
                index = text.index(index, offsetBy: 3)
            } else if text[index...].hasPrefix("OR") {
                index = text.index(index, offsetBy: 2)
            } else {
                return nil
            }
        }
    }
}
