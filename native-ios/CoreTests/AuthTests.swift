import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import P100Core

final class MockTransport: HTTPTransport {
    var responses: [(Int, String)] = []
    var failure: Error?
    private(set) var requests: [URLRequest] = []

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        if let failure { throw failure }
        let (status, body) = responses.isEmpty ? (200, "{}") : responses.removeFirst()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }

    func body(_ index: Int) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: requests[index].httpBody ?? Data())) as? [String: Any] ?? [:]
    }
}

struct Offline: Error {}

final class AuthTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let sessionJSON = #"{"access_token":"a1","refresh_token":"r1","expires_in":3600,"expires_at":1800003600,"user":{"id":"6a1f3c1e-0000-4000-8000-000000000001","email":"runner@example.com"}}"#

    func client(_ transport: MockTransport) -> SupabaseAuthClient {
        var client = SupabaseAuthClient(config: .project100m, transport: transport)
        client.now = { [now] in now }
        return client
    }

    func testLinkParsing() {
        let verify = "https://rbryddekjwytcoqqgcgu.supabase.co/auth/v1/verify?token=abc123&type=magiclink&redirect_to=https://x"
        XCTAssertEqual(AuthLink.parse(verify), .tokenHash(hash: "abc123", type: "email"))
        XCTAssertEqual(AuthLink.parse("project100m://auth-callback?token_hash=h&type=email"), .tokenHash(hash: "h", type: "email"))
        XCTAssertEqual(AuthLink.parse("https://site/#access_token=a&refresh_token=r&expires_in=60&token_type=bearer"),
                       .tokens(access: "a", refresh: "r", expiresIn: 60))
        XCTAssertEqual(AuthLink.parse("project100m://auth-callback#error=access_denied&error_description=Email+link+is+invalid"),
                       .error("Email+link+is+invalid"))
        XCTAssertNil(AuthLink.parse("https://evil.example/auth/v1/verify?token=abc&type=magiclink"))
        XCTAssertNil(AuthLink.parse("https://rbryddekjwytcoqqgcgu.supabase.co/auth/v1/verify?token=abc&type=recovery"))
        XCTAssertNil(AuthLink.parse("hello"))
    }

    func testSendEmailSignInUsesExistingAccountsOnly() async throws {
        let transport = MockTransport()
        try await client(transport).sendEmailSignIn("  Runner@Example.com ")
        let request = transport.requests[0]
        XCTAssertEqual(request.url?.path, "/auth/v1/otp")
        XCTAssertTrue(request.url?.query?.contains("redirect_to=project100m://auth-callback") ?? false)
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), SupabaseConfig.project100m.publishableKey)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(transport.body(0)["email"] as? String, "runner@example.com")
        XCTAssertEqual(transport.body(0)["create_user"] as? Bool, false)
        do { try await client(transport).sendEmailSignIn("not-an-email"); XCTFail() } catch {
            XCTAssertEqual(error as? AuthError, .invalidEmail)
        }
    }

    func testVerifyCodeAndErrorMapping() async throws {
        let transport = MockTransport()
        transport.responses = [(200, sessionJSON), (403, #"{"code":403,"error_code":"otp_expired","msg":"Token has expired or is invalid"}"#)]
        let session = try await client(transport).verifyEmailCode(email: "runner@example.com", code: "123 456")
        XCTAssertEqual(session.user.email, "runner@example.com")
        XCTAssertEqual(session.expiresAt, Date(timeIntervalSince1970: 1_800_003_600))
        XCTAssertEqual(transport.body(0)["token"] as? String, "123456")
        do { _ = try await client(transport).verifyEmailCode(email: "runner@example.com", code: "123456"); XCTFail() } catch {
            let error = try XCTUnwrap(error as? AuthError)
            XCTAssertEqual(error, .rejected(status: 403, code: "otp_expired", message: "Token has expired or is invalid"))
            XCTAssertTrue(error.errorDescription!.contains("หมดอายุ"))
        }
        do { _ = try await client(transport).verifyEmailCode(email: "runner@example.com", code: "12ab"); XCTFail() } catch {
            XCTAssertEqual(error as? AuthError, .invalidCode)
        }
    }

    func testTokenHashAndFragmentCompletion() async throws {
        let transport = MockTransport()
        transport.responses = [(200, sessionJSON), (200, #"{"id":"6a1f3c1e-0000-4000-8000-000000000001","email":"runner@example.com"}"#)]
        _ = try await client(transport).complete(.tokenHash(hash: "h", type: "email"))
        XCTAssertEqual(transport.body(0)["token_hash"] as? String, "h")
        let session = try await client(transport).complete(.tokens(access: "a", refresh: "r", expiresIn: 60))
        XCTAssertEqual(transport.requests[1].value(forHTTPHeaderField: "Authorization"), "Bearer a")
        XCTAssertEqual(session.expiresAt, now.addingTimeInterval(60))
    }

    func saved(expiresIn: TimeInterval) -> AuthSession {
        AuthSession(accessToken: "old", refreshToken: "r0", expiresAt: now.addingTimeInterval(expiresIn),
                    user: AuthUser(id: "6a1f3c1e-0000-4000-8000-000000000001", email: nil))
    }

    func testRestoreValidRefreshInvalidAndOffline() async {
        let transport = MockTransport()
        let store = InMemorySessionStore(saved(expiresIn: 3000))
        let controller = AuthSessionController(client: client(transport), store: store)
        let restoredValid = await controller.restore()
        XCTAssertEqual(restoredValid, .signedIn(saved(expiresIn: 3000)))
        XCTAssertTrue(transport.requests.isEmpty, "Unexpired session is restored without network")

        store.session = saved(expiresIn: 30)
        transport.responses = [(200, sessionJSON)]
        guard case .signedIn(let fresh) = await controller.restore() else { return XCTFail() }
        XCTAssertEqual(fresh.accessToken, "a1")
        XCTAssertEqual(store.session?.refreshToken, "r1")

        store.session = saved(expiresIn: -10)
        transport.failure = Offline()
        let offline = await controller.restore()
        XCTAssertEqual(offline, .offline(saved(expiresIn: -10)))
        XCTAssertNotNil(store.session, "Offline restore keeps the session")

        transport.failure = nil
        transport.responses = [(400, #"{"error_code":"refresh_token_not_found","msg":"Invalid Refresh Token"}"#)]
        let revoked = await controller.restore()
        XCTAssertEqual(revoked, .signedOut)
        XCTAssertNil(store.session)
    }

    func testSignOutAlwaysClearsLocalSession() async {
        let transport = MockTransport()
        transport.failure = Offline()
        let store = InMemorySessionStore(saved(expiresIn: 3000))
        await AuthSessionController(client: client(transport), store: store).signOut()
        XCTAssertNil(store.session)
        XCTAssertTrue(transport.requests[0].url?.query?.contains("scope=local") ?? false)
    }
}
