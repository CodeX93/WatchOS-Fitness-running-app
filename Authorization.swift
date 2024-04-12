import Foundation

class AuthenticationService: ObservableObject {
    @Published var isLoggedIn = false
    @Published var token = ""
    @Published var userId = ""
    @Published var showErrorAlert = false
    @Published var errorMessage = ""

    func login(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Email and password cannot be empty."
            self.showErrorAlert = true
            return
        }
        
        let url = URL(string: "https://runcentive1.bubbleapps.io/version-test/api/1.1/wf/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer 1930ea9a9991b1afb8420b4694d57c27", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "email": email,
            "password": password
        ]
        request.httpBody = bodyParameters
            .map { (key, value) in
                guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return "" }
                return "\(key)=\(encodedValue)"
            }
            .joined(separator: "&")
            .data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = data,
                       let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let response = jsonResponse["response"] as? [String: Any],
                       let token = response["token"] as? String,
                       let userId = response["user_id"] as? String {
                        self.token = token
                        self.userId = userId
                        self.isLoggedIn = true
                    } else {
                        self.errorMessage = "Failed to parse response."
                        self.showErrorAlert = true
                    }
                } else {
                    self.errorMessage = "Invalid credentials or server error occurred."
                    self.showErrorAlert = true
                }
            }
        }.resume()
    }
}
