import Foundation
import Testing
@testable import MyHomeApp

struct HubAPIErrorTests {
    @Test
    func noServerSelectedDescribesMissingConfiguration() {
        let description = HubAPIError.noServerSelected.errorDescription
        #expect(description == "No server is selected. Setup a server first.")
    }

    @Test
    func transportDescribesNetworkFailure() {
        let description = HubAPIError.transport.errorDescription
        #expect(description == "Cannot reach the server. Are you connected to the same network?")
    }

    @Test
    func decodingIncludesUnderlyingMessage() {
        let description = HubAPIError.decoding("missing key").errorDescription
        #expect(description == "Failed to decode the server response: missing key")
    }

    @Test
    func unauthorizedDescribesAuthFailure() {
        let description = HubAPIError.unauthorized.errorDescription
        #expect(description == "The request was not authorized.")
    }

    @Test
    func forbiddenDescribesForbiddenRequest() {
        let description = HubAPIError.forbidden.errorDescription
        #expect(description == "The request was forbidden")
    }

    @Test
    func validationSurfacesUnderlyingMessage() {
        let description = HubAPIError.validation("email", "must be a valid email").errorDescription
        #expect(description == "must be a valid email")
    }

    @Test
    func notFoundDescribesMissingResource() {
        let description = HubAPIError.notFound.errorDescription
        #expect(description == "The requested resource was not found")
    }

    @Test
    func conflictDescribesConflictingState() {
        let description = HubAPIError.conflict.errorDescription
        #expect(description == "The request conflicts with the current state of the server")
    }

    @Test
    func unexpectedDescribesGenericFailure() {
        let description = HubAPIError.unexpected.errorDescription
        #expect(description == "Something went wrong")
    }
}
