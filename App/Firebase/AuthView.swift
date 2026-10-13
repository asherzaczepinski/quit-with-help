import SwiftUI
import AuthenticationServices
import CryptoKit

// Motivating intro + Sign in with Apple or continue as a guest (the pre-login screen).
struct AuthView: View {
    @EnvironmentObject var auth: AuthModel
    @State private var currentNonce: String?
    @State private var error: String?

    var body: some View {
        ZStack {
            QWBackground()
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        Text("Quit With Help").font(.round(34, .heavy)).foregroundStyle(QW.accent)
                    }
                    .padding(.top, 44)
                    .padding(.bottom, 6)

                    point("person.2.fill", "Telling a friend doubles your odds",
                          "People who sent weekly progress to a friend hit their goals ~70% of the time — vs ~35% who kept them to themselves. (Matthews, Dominican University)")
                    point("link", "It takes ~66 days, not 21",
                          "A new behavior takes about 66 days on average to become automatic. The streak keeps you in it long enough to get there. (Lally et al., UCL, 2010)")
                    point("clock.fill", "Cravings pass",
                          "An urge usually peaks and fades within a few minutes, whether or not you give in. Tap \"I'm craving it\" and ride it out with your friends.")
                    point("bell.fill", "Not another tracker you'll ghost",
                          "Every other app just nudges you. Quit With Help tells the people who actually care the moment you slip.")

                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        handle(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.top, 8)

                    Button {
                        Task {
                            do { try await auth.signInAsGuest() }
                            catch { self.error = error.localizedDescription }
                        }
                    } label: { Text("Continue as guest") }
                    .buttonStyle(QWButtonStyle(bg: QW.surface, fg: QW.text))

                    if let error {
                        Text(error).font(.footnote).foregroundStyle(QW.danger)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 20)
                .padding(24)
            }
        }
        .preferredColorScheme(.light)
    }

    private func point(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(QW.accent).frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.round(16, .semibold)).foregroundStyle(QW.text)
                Text(body).font(.system(size: 14)).foregroundStyle(QW.muted)
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .qwCard(16)
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let tokenData = cred.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                error = "Couldn't read your Apple sign-in."
                return
            }
            Task {
                do {
                    try await auth.signInWithApple(idToken: idToken, rawNonce: nonce, fullName: cred.fullName)
                } catch {
                    self.error = error.localizedDescription
                }
            }
        case .failure(let err):
            if let authErr = err as? ASAuthorizationError {
                switch authErr.code {
                case .canceled: return
                case .unknown, .notHandled, .failed:
                    error = "Apple sign-in couldn't start. On the Simulator, open Settings → \"Sign in to your iPhone\" with an Apple ID first, then run again from Xcode (⌘R)."
                    return
                default: break
                }
            }
            error = err.localizedDescription
        }
    }
}

// ── Nonce helpers (from Firebase's docs) ──
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if status != errSecSuccess {
        fatalError("SecRandomCopyBytes failed with OSStatus \(status)")
    }
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(randomBytes.map { charset[Int($0) % charset.count] })
}

private func sha256(_ input: String) -> String {
    let hashed = SHA256.hash(data: Data(input.utf8))
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}
