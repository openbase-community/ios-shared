import Testing
@testable import AllAuthSwift

@Test func clientExists() async throws {
    #expect(AllAuthClient.shared != nil)
}
