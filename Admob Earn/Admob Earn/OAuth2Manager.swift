import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

final class OAuth2Manager: NSObject, ASWebAuthenticationPresentationContextProviding {

    // From Google Cloud Console (iOS OAuth client)
    private let clientID = "682662313320-6k751ok28ij6njn9agsa6o1p5020km55.apps.googleusercontent.com"
    private let reversedClientID = "com.googleusercontent.apps.682662313320-6k751ok28ij6njn9agsa6o1p5020km55"

    // ✅ Correct custom-scheme redirect URI
    private lazy var redirectURI = URL(string: "\(reversedClientID):/oauthredirect")!

    private let authURL  = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    private let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!

    private var session: ASWebAuthenticationSession?
    private var codeVerifier: String?
    private var pendingState: String?

    // Presenting window
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }

    func signIn() async throws -> String {
        let verifier  = randomString(length: 64)
        codeVerifier  = verifier
        let challenge = codeChallenge(for: verifier)
        let state     = randomString(length: 32)
        pendingState  = state

        var components = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id",             value: clientID),
            URLQueryItem(name: "redirect_uri",          value: redirectURI.absoluteString),
            URLQueryItem(name: "response_type",         value: "code"),
            URLQueryItem(name: "scope",                 value: "https://www.googleapis.com/auth/admob.readonly"),
            URLQueryItem(name: "code_challenge",        value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state",                 value: state),
            // optional but useful:
            URLQueryItem(name: "access_type",           value: "offline"),
            URLQueryItem(name: "prompt",                value: "consent"),
            URLQueryItem(name: "include_granted_scopes",value: "true")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        return try await withCheckedThrowingContinuation { continuation in
            session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: reversedClientID // scheme part only
            ) { [weak self] callbackURL, error in
                guard let self = self else { return }
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard
                    let callbackURL = callbackURL,
                    let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems,
                    let returnedState = items.first(where: { $0.name == "state" })?.value,
                    returnedState == self.pendingState,
                    let code = items.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                Task {
                    do {
                        let token = try await self.exchangeCodeForToken(code: code)
                        continuation.resume(returning: token)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            session?.presentationContextProvider = self
            session?.prefersEphemeralWebBrowserSession = false
            _ = session?.start()
        }
    }

    private func exchangeCodeForToken(code: String) async throws -> String {
        guard let verifier = codeVerifier else { throw URLError(.unknown) }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"

        // ✅ Proper x-www-form-urlencoded body
        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "client_id",     value: clientID),
            URLQueryItem(name: "code",          value: code),
            URLQueryItem(name: "code_verifier", value: verifier),
            URLQueryItem(name: "grant_type",    value: "authorization_code"),
            URLQueryItem(name: "redirect_uri",  value: redirectURI.absoluteString)
        ]
        request.httpBody = body.query?.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        // Helpful error surface
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "OAuth", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        return token.accessToken
    }

    private func randomString(length: Int) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    private func codeChallenge(for verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Int
        let refreshToken: String?
        let tokenType: String
        private enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn   = "expires_in"
            case refreshToken = "refresh_token"
            case tokenType   = "token_type"
        }
    }
}

