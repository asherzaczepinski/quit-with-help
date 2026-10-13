import SwiftUI
import FirebaseAuth
import AuthenticationServices

// Firebase auth via Sign in with Apple, or as a guest (anonymous).
@MainActor
final class AuthModel: ObservableObject {
    @Published var userID: String?
    @Published var email: String = ""
    @Published var isLoading = true

    private var handle: AuthStateDidChangeListenerHandle?

    var isSignedIn: Bool { userID != nil }

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let uid = user?.uid
            let mail = user?.email ?? ""
            Task { @MainActor in
                self?.userID = uid
                self?.email = mail
                self?.isLoading = false
            }
        }
    }

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )
        _ = try await Auth.auth().signIn(with: credential)
    }

    // Guest: an anonymous Firebase account, no Apple ID needed.
    func signInAsGuest() async throws {
        _ = try await Auth.auth().signInAnonymously()
    }

    func signOut() async {
        try? Auth.auth().signOut()
        userID = nil
    }
}
