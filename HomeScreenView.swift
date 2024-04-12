import SwiftUI

// Define a struct for the race data
struct Race: Identifiable, Decodable {
    var id: String
    var title: String
    var prize: Double
    var participationFee: Double
    var distance: Double
    var closingDate: Date
    var backgroundImage: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title = "Title"
        case prize
        case participationFee = "Participation-Fee"
        case distance = "Distance"
        case closingDate = "Closing-date"
        case backgroundImage = "background-image"
    }
}

// Define a view model for the HomeScreenView
class HomeScreenViewModel: ObservableObject {
    @Published var races: [Race] = []
    
    func fetchRaces(userId: String, token: String) {
        guard let url = URL(string: "https://runcentive1.bubbleapps.io/version-test/api/1.1/wf/send_registered_races") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["userId": userId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "Empty")")
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("No data received")
                return
            }
            print("Response data: \(String(data: data, encoding: .utf8) ?? "Empty")")
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                let decodedResponse = try decoder.decode(RacesResponse.self, from: data)
                DispatchQueue.main.async {
                    self.races = decodedResponse.response.races
                    print("Decoded races: \(self.races)")
                }
            } catch {
                print("Error decoding response: \(error)")
            }
        }.resume()
    }
}

// Define a struct for the API response
struct RacesResponse: Decodable {
    var status: String
    var response: RacesData
}

struct RacesData: Decodable {
    var races: [Race]
}

// Define the RaceCard view to display the race data
struct RaceCard: View {
    var race: Race
    var userId: String
    @State private var isNavigationActive = false
    @State private var raceId: String = "" // Move raceId state here

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(race.title)
                    .font(.system(size: 10, weight: .bold, design: .default))
                    .foregroundColor(.white)
                Spacer()
                Text("$\(race.prize, specifier: "%.0f")")
                    .font(.system(size: 10, weight: .regular, design: .default))
                    .foregroundColor(.yellow)
            }
            AsyncImage(url: URL(string: "https:"+race.backgroundImage)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 80)
                    .clipped()
                    .cornerRadius(10)
            } placeholder: {
                Color.gray
                    .frame(height: 100)
                    .cornerRadius(16)
            }
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Entry Fee:")
                        .font(.system(size: 8, weight: .regular, design: .default))
                        .foregroundColor(.white)
                    Text("$\(race.participationFee, specifier: "%.0f")")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Aligns to the left and takes up maximum available space

                VStack(alignment: .trailing, spacing: 5) {
                    Text("Distance:")
                        .font(.system(size: 8, weight: .regular, design: .default))
                        .foregroundColor(.white)
                    Text("\(race.distance, specifier: "%.1f") miles")
                        .font(.system(size: 10, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .trailing) // Aligns to the right and takes up maximum available space
            }

            Button(action: {
                isNavigationActive = true
                raceId = race.id // Update raceId when the button is tapped
                print(raceId, userId)
            }) {
                Text("Run")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(5)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(red: 60 / 255, green: 61 / 255, blue: 60 / 255))
        .cornerRadius(10)
        .shadow(radius: 5)
        .fullScreenCover(isPresented: $isNavigationActive) {
            RunScreenView(userId: userId, raceId: raceId)
        }
    }
}


// Formatter for the race closing date
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

// Define the HomeScreenView to use the view model and display the races
struct HomeScreenView: View {
    let userId: String
    let token: String
    
    @ObservedObject var viewModel = HomeScreenViewModel()
    @State private var raceId: String = ""
    @State private var isNavigationActive: Bool = false // Track navigation state
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.races) { race in
                            RaceCard(race: race, userId: userId)
                                .onTapGesture {
                                    raceId = race.id // Update raceId when a card is tapped
                                    isNavigationActive = true // Activate navigation
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Races")
            .onAppear {
                viewModel.fetchRaces(userId: userId, token: "1930ea9a9991b1afb8420b4694d57c27")
            }
        }
        .background(
            NavigationLink(destination: RunScreenView(userId: userId, raceId: raceId), label: {
                Text("Go to Destination View")
            })
        )
    }
}







