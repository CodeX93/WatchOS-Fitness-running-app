import SwiftUI
import CoreLocation

// Define a class to handle location updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    @Published var distanceTravelled: Double = 0.0
    private var startLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        startLocation = nil
        distanceTravelled = 0.0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        
        if let startLocation = startLocation {
            let distance = startLocation.distance(from: latestLocation)
            DispatchQueue.main.async {
                self.distanceTravelled += distance
            }
        } else {
            startLocation = latestLocation
        }
    }
}

struct RunScreenView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var timeElapsed = 0
    @State private var timerRunning = false
    @State private var showStopButton = false
    
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let userId: String
    let raceId: String
    
    init(userId: String, raceId: String) {
        self.userId = userId
        self.raceId = raceId
    }

    var body: some View {
        VStack {
            Text(formatTime(timeElapsed))
                .fontWeight(.heavy)
                .padding(.top)
                .onReceive(timer) { _ in
                    if self.timerRunning {
                        self.timeElapsed += 1
                    }
                }

            Spacer()

            Text("Distance Travelled")
                .font(.system(size: 8, weight: .bold, design: .default))
                .multilineTextAlignment(.center)
                .padding(.bottom, 10.0)
            Text("\(self.locationManager.distanceTravelled) m")
                .font(.system(size: 8, weight: .regular, design: .default))
                .foregroundColor(.white)

            Spacer()

            HStack {
                if showStopButton {
                    Button(action: stopRun) {
                        Image(systemName: "stop.fill")
                            .imageScale(.large)
                            .foregroundStyle(.red)
                    }
                }

                Button(action: startOrPauseRun) {
                    Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                        .imageScale(.large)
                        .foregroundStyle(.green)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .onAppear {
            self.locationManager.startUpdatingLocation()
        }
    }

    func formatTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func stopRun() {
        timer.upstream.connect().cancel()
        timeElapsed = 0
        timerRunning = false
        showStopButton = false
        let distance = locationManager.distanceTravelled
        locationManager.stopUpdatingLocation()
        
        // Send data to the API
        sendDataToAPI(raceId: raceId, userId: userId, distance: distance)
    }
    
    func startOrPauseRun() {
        if timerRunning {
            locationManager.stopUpdatingLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
        timerRunning.toggle()
        showStopButton = !timerRunning
    }
    
    // Function to send data to the API
    func sendDataToAPI(raceId: String, userId: String, distance: Double) {
        guard let url = URL(string: "https://runcentive1.bubbleapps.io/version-test/api/1.1/wf/modify-race-participant-data") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer 1930ea9a9991b1afb8420b4694d57c27", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "raceId": raceId,
            "userId": userId,
            "distanceCovered": distance
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending data to API: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("Error response from API: \(httpResponse.statusCode)")
                return
            }
            print("Data sent to API successfully")
        }.resume()
    }
}
