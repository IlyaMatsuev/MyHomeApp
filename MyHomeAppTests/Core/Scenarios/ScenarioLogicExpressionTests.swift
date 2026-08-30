import Testing
@testable import MyHomeApp

struct ScenarioLogicExpressionTests {
    // MARK: - accepted expressions

    @Test(arguments: [
        "1 AND 2 AND 3",
        "1 OR 2 OR 3",
        "(1 OR 2) AND 3",
        "1 and 2 and 3",
        "1AND2OR3",
        "  1   OR   2 OR 3 "
    ])
    func expressionsTheHubAcceptsAreValid(expression: String) {
        #expect(ScenarioLogicExpression.isValid(expression, sourceCount: 3))
    }

    @Test
    func aSingleSourceIsReferencedByItsBareIndex() {
        #expect(ScenarioLogicExpression.isValid("1", sourceCount: 1))
    }

    // MARK: - rejected expressions

    @Test(arguments: [
        "",
        "   ",
        "1 AND",
        "AND 1",
        "1 2 3",
        "1 XOR 2 XOR 3",
        "1 & 2 & 3",
        "one AND two AND three"
    ])
    func malformedExpressionsAreRejected(expression: String) {
        #expect(!ScenarioLogicExpression.isValid(expression, sourceCount: 3))
    }

    @Test(arguments: ["NOT 1", "NOT (1 AND 2) OR 3", "1 AND NOT 2"])
    func notIsRejectedBecauseTheHubDoesNotSupportIt(expression: String) {
        #expect(!ScenarioLogicExpression.isValid(expression, sourceCount: 3))
    }

    // MARK: - operand bounds

    @Test
    func everySourceMustBeReferencedExactlyOnce() {
        #expect(!ScenarioLogicExpression.isValid("1", sourceCount: 3), "Leaves sources 2 and 3 unreferenced")
        #expect(!ScenarioLogicExpression.isValid("1 AND 2", sourceCount: 3))
        #expect(!ScenarioLogicExpression.isValid("1 AND 2 AND 3 AND 3", sourceCount: 3))
    }

    @Test
    func indexesOutsideTheSourceRangeAreRejected() {
        #expect(!ScenarioLogicExpression.isValid("1 AND 2 AND 4", sourceCount: 3))
        #expect(!ScenarioLogicExpression.isValid("0 AND 1 AND 2", sourceCount: 3))
    }

    @Test
    func nothingIsValidWithoutSources() {
        #expect(!ScenarioLogicExpression.isValid("1", sourceCount: 0))
    }

    @Test
    func expressionsLongerThanTheHubLimitAreRejected() {
        let sourceCount = 30
        let expression = (1...sourceCount).map(String.init).joined(separator: " AND ")

        #expect(expression.count > ScenarioLimits.logicLength.upperBound)
        #expect(!ScenarioLogicExpression.isValid(expression, sourceCount: sourceCount))
    }
}
