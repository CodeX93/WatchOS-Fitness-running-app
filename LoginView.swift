import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @ObservedObject var authService = AuthenticationService()

    var body: some View {
        NavigationView {
            VStack {
                TextField("Email", text: $email)
                    .padding()

                SecureField("Password", text: $password)
                    .padding()

                Button("Log In") {
                    authService.login(email: email, password: password)
                    print(authService.userId,authService.token)
                }
                .padding()
                .alert(isPresented: $authService.showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(authService.errorMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
        .fullScreenCover(isPresented: $authService.isLoggedIn) {
            HomeScreenView(userId: authService.userId, token: authService.token)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
