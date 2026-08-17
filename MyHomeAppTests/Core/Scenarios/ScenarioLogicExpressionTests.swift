import Foundation
import Testing
@testable import MyHomeApp

struct ScenarioLogicExpressionTests {
    // MARK: - accepted expressions

    @Test(arguments: [
        "1",
        "1 AND 2",
        "1 OR 2",
        "(1 OR 2) AND 3",
        "NOT 1",
        "NOT (1 AND 2) OR 3",
        "((1))",
        "1 and 2",
        "1AND2",
        "  1   OR   2  ",
    ])
    func validExpressionsAreAccepted(expression: String) {
        #expect(ScenarioLogicExpression.isValid(expression, sourceCount: 3))
    }

    // MARK: - rejected expressions

    @Test(arguments: [
        "",
        "   ",
        "(1 OR 2",
        "1 OR 2)",
        "1 AND",
        "AND 1",
        "1 2",
        "1 XOR 2",
        "1 & 2",
        "one AND two",
        "1.5",
    ])
    func malformedExpressionsAreRejected(expression: String) {
        #expect(!ScenarioLogicExpression.isValid(expression, sourceCount: 3))
    }

    // MARK: - index bounds

    @Test
    func indexesOutsideTheSourceRangeAreRejected() {
        #expect(!ScenarioLogicExpression.isValid("4", sourceCount: 3))
        #expect(!ScenarioLogicExpression.isValid("1 AND 4", sourceCount: 3))
        #expect(!ScenarioLogicExpression.isValid("0", sourceCount: 3))
    }

    @Test
    func nothingIsValidWithoutSources() {
        #expect(!ScenarioLogicExpression.isValid("1", sourceCount: 0))
    }
}
