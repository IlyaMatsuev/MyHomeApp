import Foundation
import Observation
import os

@Observable
@MainActor
final class RegistrationStore {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "RegistrationStore")

    enum State: Equatable {
        case loading
        case absent
        case pending(RegistrationRequest)
    }

    private(set) var state: State = .loading

    private let service: RegistrationService
    private let persistence: RegistrationPersistence

    var pendingRequest: RegistrationRequest? {
        if case .pending(let request) = state {
            return request
        }
        return nil
    }

    var hasPendingRequest: Bool {
        pendingRequest != nil
    }

    init(service: RegistrationService, persistence: RegistrationPersistence) {
        self.service = service
        self.persistence = persistence
    }

    func load() async {
        do {
            if let request = try persistence.load() {
                state = .pending(request)
            } else {
                state = .absent
            }
        } catch {
            Self.logger.error("Failed to load a registration request: \(error.localizedDescription)")
            state = .absent
        }
    }

    func clear() {
        do {
            try persistence.clear()
        } catch {
            Self.logger.error("Failed to clear a registration request: \(error.localizedDescription)")
        }
        state = .absent
    }

    func requestAccess(email: String, comment: String?) async throws {
        let previous = pendingRequest
        let request = try await service.requestAccess(email: email, comment: comment)
        try? persistence.save(request)
        state = .pending(request)

        if let previous {
            cancelRequest(requestId: previous.externalId)
        }
    }

    @discardableResult
    func refreshStatus() async throws -> RegistrationStatus {
        guard let request = pendingRequest else {
            throw RegistrationError.requestNotFound
        }
        let status = try await service.checkStatus(requestId: request.externalId)
        let updated = request.withStatus(status)
        try? persistence.save(updated)
        state = .pending(updated)
        return status
    }

    func cancelAndClear() {
        if let request = pendingRequest {
            cancelRequest(requestId: request.externalId)
        }
        clear()
    }

    private func cancelRequest(requestId: String) {
        let service = service
        Task { try? await service.cancelRequest(requestId: requestId) }
    }
}
