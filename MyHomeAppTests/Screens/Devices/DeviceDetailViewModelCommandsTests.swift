import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

/// The device sheet firing stateless commands and deleting the device.
@MainActor
struct DeviceDetailViewModelCommandsTests {
    private static let speaker = Device.fixture(name: "Nest", type: .speaker, brand: .google)
        .withConfig(MockDeviceConfigs.googleSpeaker)
        .build()

    private let service: StubDeviceService
    private let toastStore: ToastStore

    init() {
        service = StubDeviceService()
        toastStore = ToastStore()
    }

    private func makeSpeakerViewModel(
        onDeleted: @escaping @MainActor (String) -> Void = { _ in }
    ) -> DeviceDetailViewModel {
        DeviceDetailViewModel(
            device: Self.speaker,
            service: service,
            toastStore: toastStore,
            onChanged: { _ in },
            onDeleted: onDeleted
        )
    }

    // MARK: - Commands

    @Test
    func sendingACommandPostsItAndToastsSuccess() async throws {
        service.sendCommandResult = { _ in .success(Self.speaker) }
        let viewModel = makeSpeakerViewModel()
        let text = try #require(viewModel.commandItems.first)

        viewModel.setCommandValue(AnyCodable("Dinner is ready"), of: text)
        await viewModel.sendCommand(text)

        #expect(service.sendCommandCalls.first?.command == ["text": AnyCodable("Dinner is ready")])
        #expect(toastStore.current?.kind == .success)
    }

    @Test
    func staysQuietAboutACommandTheUserHasNotTouched() throws {
        let viewModel = makeSpeakerViewModel()
        let text = try #require(viewModel.commandItems.first)

        #expect(viewModel.commandError(of: text) == nil)
        #expect(viewModel.canSend(text) == false)
    }

    @Test
    func explainsAnEmptyCommandOnceTheUserTriesToSendIt() async throws {
        let viewModel = makeSpeakerViewModel()
        let text = try #require(viewModel.commandItems.first)

        await viewModel.sendCommand(text)

        #expect(viewModel.commandError(of: text) != nil)
        #expect(service.sendCommandCalls.isEmpty)
    }

    @Test
    func refusesToSendACommandTheHubWouldReject() async throws {
        let viewModel = makeSpeakerViewModel()
        let text = try #require(viewModel.commandItems.first)

        viewModel.setCommandValue(AnyCodable(""), of: text)

        #expect(viewModel.canSend(text) == false)
        await viewModel.sendCommand(text)
        #expect(service.sendCommandCalls.isEmpty)
    }

    // MARK: - Deletion

    @Test
    func deletionIsConfirmedBeforeAnythingIsSent() {
        let viewModel = makeSpeakerViewModel()

        viewModel.requestDeletion()

        #expect(viewModel.isConfirmingDeletion)
        #expect(service.deleteDeviceCalls.isEmpty)
    }

    @Test
    func cancellingDeletionSendsNothing() async {
        let viewModel = makeSpeakerViewModel()
        viewModel.requestDeletion()

        viewModel.cancelDeletion()

        #expect(viewModel.isConfirmingDeletion == false)
        #expect(service.deleteDeviceCalls.isEmpty)
    }

    @Test
    func confirmingDeletionDeletesAndReportsBack() async {
        var deletedId: String?
        let viewModel = makeSpeakerViewModel(onDeleted: { deletedId = $0 })
        viewModel.requestDeletion()

        await viewModel.confirmDeletion()

        #expect(service.deleteDeviceCalls == [Self.speaker.id])
        #expect(deletedId == Self.speaker.id)
        #expect(viewModel.isConfirmingDeletion == false)
    }

    @Test
    func aFailedDeletionKeepsTheDeviceAndToasts() async {
        service.deleteDeviceResult = .failure(HubAPIError.forbidden)
        var deletedId: String?
        let viewModel = makeSpeakerViewModel(onDeleted: { deletedId = $0 })

        await viewModel.confirmDeletion()

        #expect(deletedId == nil)
        #expect(toastStore.current?.kind == .error)
        #expect(viewModel.isDeleting == false)
    }
}
