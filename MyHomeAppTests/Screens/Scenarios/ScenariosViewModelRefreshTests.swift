import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct ScenariosViewModelRefreshTests {
    private let service: StubScenarioService
    private let deviceService: StubDeviceService
    private let toastStore: ToastStore
    private let viewModel: ScenariosViewModel

    init() {
        service = StubScenarioService()
        deviceService = StubDeviceService()
        toastStore = ToastStore()
        viewModel = ScenariosViewModel(service: service, deviceService: deviceService, toastStore: toastStore)
    }

    private struct SampleError: LocalizedError {
        var errorDescription: String? { "Boom" }
    }

    @Test
    func refreshReplacesTheListWithWhatTheHubReturns() async {
        service.setScenarios([Scenario.fixture(name: "Warm light on").build()])
        await viewModel.load()

        service.setScenarios([Scenario.fixture(name: "Movie time").build()])
        await viewModel.refresh()

        #expect(viewModel.scenarios.map(\.name) == ["Movie time"])
        #expect(viewModel.state == .loaded)
    }

    @Test
    func refreshKeepsTheListWhenTheHubFails() async throws {
        service.setScenarios([Scenario.fixture(name: "Warm light on").build()])
        await viewModel.load()

        service.setScenariosError(SampleError())
        await viewModel.refresh()

        #expect(viewModel.scenarios.map(\.name) == ["Warm light on"], "A pull must not wipe the list")
        #expect(viewModel.state == .loaded, "…and must not replace it with the error screen")
        let toast = try #require(toastStore.current)
        #expect(toast.kind == .error, "The toast is what reports the failed refresh")
    }

    @Test
    func loadStillClearsTheListWhenTheHubFails() async {
        service.setScenarios([Scenario.fixture(name: "Warm light on").build()])
        await viewModel.load()

        service.setScenariosError(SampleError())
        await viewModel.load()

        #expect(viewModel.scenarios.isEmpty)
        #expect(viewModel.state == .failed(ScenarioError.generic))
    }
}
