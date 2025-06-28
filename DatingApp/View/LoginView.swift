import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()

    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false

    var body: some View {
        VStack(spacing: 20) {
            Text(isSigningUp ? "Sign Up" : "Sign In")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                if isSigningUp {
                    authVM.signUp(email: email, password: password)
                } else {
                    authVM.signIn(email: email, password: password)
                }
            }) {
                Text(isSigningUp ? "Create Account" : "Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(email.isEmpty || password.isEmpty)

            Button(action: {
                isSigningUp.toggle()
            }) {
                Text(isSigningUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}
