import Foundation

struct HubRegistrationService: RegistrationService {
    private struct CreateRequest: Encodable {
        let email: String
        let comment: String?
    }

    private struct RegistrationRequestResponse: Decodable {
        let externalId: String
        let requesterEmail: String
        let requesterComment: String?
        let status: RegistrationRequestStatus
        let role: UserRole
        // swiftlint:disable:next inclusive_language
        let blackListed: Bool
    }

    private let client: MyHomeAPIClient

    init(client: MyHomeAPIClient) {
        self.client = client
    }

    func requestAccess(email: String, comment: String?) async throws -> RegistrationRequest {
        do {
            let body = CreateRequest(email: email, comment: comment)
            let request = try HubRequest.post("/auth/register/requests", body, protected: false)
            let response: RegistrationRequestResponse = try await client.send(request)
            return Self.mapRegistrationRequest(response)
        } catch let error as HubAPIError {
            throw Self.mapError(error)
        } catch {
            throw RegistrationError.unexpected
        }
    }

    func refreshRequest(requestId: String) async throws -> RegistrationRequest {
        do {
            let request = HubRequest.get("/auth/register/requests/\(requestId)", protected: false)
            let response: RegistrationRequestResponse = try await client.send(request)
            return Self.mapRegistrationRequest(response)
        } catch let error as HubAPIError {
            throw Self.mapError(error)
        } catch {
            throw RegistrationError.unexpected
        }
    }

    func cancelRequest(requestId: String) async throws {
        do {
            let request = HubRequest.delete("/auth/register/requests/\(requestId)", protected: false)
            try await client.send(request)
        } catch let error as HubAPIError {
            throw Self.mapError(error)
        } catch {
            throw RegistrationError.unexpected
        }
    }

    private static func mapRegistrationRequest(_ response: RegistrationRequestResponse) -> RegistrationRequest {
        return RegistrationRequest(
            externalId: response.externalId,
            email: response.requesterEmail,
            requesterComment: response.requesterComment,
            status: response.status,
            role: response.role,
            blocked: response.blackListed
        )
    }

    private static func mapError(_ error: HubAPIError) -> RegistrationError {
        switch error {
        case .conflict: .alreadyRequested
        case .notFound: .requestNotFound
        case .forbidden: .blocked
        default: .unexpected
        }
    }
}
