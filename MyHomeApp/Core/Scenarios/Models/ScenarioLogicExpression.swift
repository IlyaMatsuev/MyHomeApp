import Foundation

/// Validator for the hub's positional trigger expressions, e.g. `"(1 OR 2) AND 3"`.
///
/// Grammar:
/// ```
/// expression := term (OR term)*
/// term       := factor (AND factor)*
/// factor     := NOT factor | "(" expression ")" | INDEX
/// ```
/// `INDEX` is a 1-based reference into `trigger.sources`.
enum ScenarioLogicExpression {
    /// `true` when `expression` parses and every index it references exists in a trigger with `sourceCount` sources.
    static func isValid(_ expression: String, sourceCount: Int) -> Bool {
        guard sourceCount > 0, let tokens = tokenize(expression), !tokens.isEmpty else { return false }
        var parser = Parser(tokens: tokens, sourceCount: sourceCount)
        return parser.parse()
    }

    private static func tokenize(_ expression: String) -> [Token]? {
        var tokens: [Token] = []
        var index = expression.startIndex

        while index < expression.endIndex {
            let character = expression[index]

            if character.isWhitespace {
                index = expression.index(after: index)
            } else if character == "(" {
                tokens.append(.open)
                index = expression.index(after: index)
            } else if character == ")" {
                tokens.append(.close)
                index = expression.index(after: index)
            } else if character.isNumber {
                let digits = expression[index...].prefix(while: \.isNumber)
                guard let value = Int(digits) else { return nil }
                tokens.append(.index(value))
                index = expression.index(index, offsetBy: digits.count)
            } else if character.isLetter {
                let word = expression[index...].prefix(while: \.isLetter)
                guard let token = Token(keyword: String(word)) else { return nil }
                tokens.append(token)
                index = expression.index(index, offsetBy: word.count)
            } else {
                return nil
            }
        }
        return tokens
    }

    private enum Token: Equatable {
        case and
        case or
        case not
        case open
        case close
        case index(Int)

        init?(keyword: String) {
            switch keyword.uppercased() {
            case "AND": self = .and
            case "OR": self = .or
            case "NOT": self = .not
            default: return nil
            }
        }
    }

    private struct Parser {
        private let tokens: [Token]
        private let sourceCount: Int
        private var position = 0

        init(tokens: [Token], sourceCount: Int) {
            self.tokens = tokens
            self.sourceCount = sourceCount
        }

        mutating func parse() -> Bool {
            guard parseExpression() else { return false }
            return position == tokens.count
        }

        private mutating func parseExpression() -> Bool {
            guard parseTerm() else { return false }
            while match(.or) {
                guard parseTerm() else { return false }
            }
            return true
        }

        private mutating func parseTerm() -> Bool {
            guard parseFactor() else { return false }
            while match(.and) {
                guard parseFactor() else { return false }
            }
            return true
        }

        private mutating func parseFactor() -> Bool {
            if match(.not) {
                return parseFactor()
            }
            if match(.open) {
                guard parseExpression() else { return false }
                return match(.close)
            }
            guard let token = peek(), case .index(let value) = token else { return false }
            position += 1
            return value >= 1 && value <= sourceCount
        }

        private func peek() -> Token? {
            position < tokens.count ? tokens[position] : nil
        }

        private mutating func match(_ token: Token) -> Bool {
            guard peek() == token else { return false }
            position += 1
            return true
        }
    }
}
