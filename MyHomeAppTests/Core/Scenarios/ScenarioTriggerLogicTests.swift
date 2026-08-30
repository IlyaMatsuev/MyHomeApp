import Foundation
import Testing
@testable import MyHomeApp

struct ScenarioTriggerLogicTests {
    // MARK: - expression(sourceCount:)

    @Test
    func allProducesAnAndExpressionOverEverySource() {
        #expect(ScenarioTriggerLogic.all.expression(sourceCount: 3) == "1 AND 2 AND 3")
    }

    @Test
    func anyProducesAnOrExpressionOverEverySource() {
        #expect(ScenarioTriggerLogic.any.expression(sourceCount: 3) == "1 OR 2 OR 3")
    }

    @Test
    func aSingleSourceProducesItsBareIndex() {
        #expect(ScenarioTriggerLogic.all.expression(sourceCount: 1) == "1")
        #expect(ScenarioTriggerLogic.any.expression(sourceCount: 1) == "1")
    }

    @Test
    func customIsSentVerbatim() {
        let logic = ScenarioTriggerLogic.custom("(1 OR 2) AND 3")

        #expect(logic.expression(sourceCount: 3) == "(1 OR 2) AND 3")
    }

    // MARK: - parse(_:sourceCount:)

    @Test
    func parseMapsTheCanonicalAndFormBackOntoAll() {
        #expect(ScenarioTriggerLogic.parse("1 AND 2 AND 3", sourceCount: 3) == .all)
    }

    @Test
    func parseMapsTheCanonicalOrFormBackOntoAny() {
        #expect(ScenarioTriggerLogic.parse("1 OR 2 OR 3", sourceCount: 3) == .any)
    }

    @Test
    func parseIgnoresSpacingAndCasing() {
        #expect(ScenarioTriggerLogic.parse("1   and    2", sourceCount: 2) == .all)
    }

    @Test
    func parseKeepsAnythingElseAsCustom() {
        #expect(ScenarioTriggerLogic.parse("(1 OR 2) AND 3", sourceCount: 3) == .custom("(1 OR 2) AND 3"))
    }

    @Test
    func parseTreatsACanonicalFormForADifferentSourceCountAsCustom() {
        #expect(ScenarioTriggerLogic.parse("1 AND 2", sourceCount: 3) == .custom("1 AND 2"))
    }

    @Test(arguments: ["", "   "])
    func parseDefaultsToAllWhenTheExpressionIsBlank(expression: String) {
        #expect(ScenarioTriggerLogic.parse(expression, sourceCount: 2) == .all)
    }

    @Test
    func parseAndExpressionRoundTrip() {
        let expression = ScenarioTriggerLogic.any.expression(sourceCount: 4)

        #expect(ScenarioTriggerLogic.parse(expression, sourceCount: 4) == .any)
    }

    // MARK: - isValid(sourceCount:)

    @Test
    func allAndAnyNeedAtLeastOneSource() {
        #expect(ScenarioTriggerLogic.all.isValid(sourceCount: 1))
        #expect(ScenarioTriggerLogic.any.isValid(sourceCount: 1))
        #expect(!ScenarioTriggerLogic.all.isValid(sourceCount: 0))
        #expect(!ScenarioTriggerLogic.any.isValid(sourceCount: 0))
    }

    @Test
    func customIsValidatedAgainstTheSourceCount() {
        #expect(ScenarioTriggerLogic.custom("(1 OR 2) AND 3").isValid(sourceCount: 3))
        #expect(!ScenarioTriggerLogic.custom("(1 OR 2) AND 4").isValid(sourceCount: 3))
        #expect(!ScenarioTriggerLogic.custom("1 OR 2").isValid(sourceCount: 3), "Leaves source 3 unreferenced")
    }

    // MARK: - mode

    @Test
    func modeAndCustomExpressionExposeTheEditorState() {
        #expect(ScenarioTriggerLogic.all.mode == .all)
        #expect(ScenarioTriggerLogic.any.mode == .any)
        #expect(ScenarioTriggerLogic.custom("1").mode == .custom)
        #expect(ScenarioTriggerLogic.all.customExpression == nil)
        #expect(ScenarioTriggerLogic.custom("(1 OR 2) AND 3").customExpression == "(1 OR 2) AND 3")
    }
}
