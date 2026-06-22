import Foundation

struct HubRegistrationService: RegistrationService {
    private struct CreateRequest: Encodable {
        let email: String
    }

    private struct CreateResponse: Decodable {
        let externalId: String
    }

    private struct StatusResponse: Decodable {
        let status: RegistrationStatus
    }

    private let client: MyHomeAPIClient

    init(client: MyHomeAPIClient) {
        self.client = client
    }

    func requestAccess(email: String) async throws -> RegistrationRequest {
        do {
            let body = CreateRequest(email: email)
            let request = try HubRequest.post("/auth/register/requests", body, protected: false)
            let response: CreateResponse = try await client.send(request)
            return RegistrationRequest(externalId: response.externalId, email: email, status: .pending)
        } catch let error as HubAPIError {
            throw Self.map(error)
        } catch {
            throw RegistrationError.unexpected
        }
    }

    func checkStatus(requestId: String) async throws -> RegistrationStatus {
        do {
            let request = HubRequest.get("/auth/register/requests/\(requestId)", protected: false)
            let response: StatusResponse = try await client.send(request)
            return response.status
        } catch let error as HubAPIError {
            throw Self.map(error)
        } catch {
            throw RegistrationError.unexpected
        }
    }

    private static func map(_ error: HubAPIError) -> RegistrationError {
        switch error {
        case .http(let status, _) where status == 409: .alreadyRequested
        case .http(let status, _) where status == 404: .requestNotFound
        default: .unexpected
        }
    }
}
