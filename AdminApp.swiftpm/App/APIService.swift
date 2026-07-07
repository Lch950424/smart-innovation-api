import Foundation

struct ElderLocationResponse: Codable {
    let status: String
    let data: [Elder]
}

struct Elder: Codable, Identifiable {
    let id: String
    let name: String
    let status: String
    let latitude: Double
    let longitude: Double
    let lastActive: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, latitude, longitude
        case lastActive = "last_active"
    }
}

struct AlertResponse: Codable {
    let status: String
    let data: [ElderAlert]
}

struct ElderAlert: Codable, Identifiable {
    let id: String
    let elderId: String
    let elderName: String
    let triggeredAt: String
    let status: String // pending, confirmed_by_admin
    let lat: Double
    let lng: Double
    
    enum CodingKeys: String, CodingKey {
        case id, status, lat, lng
        case elderId = "elder_id"
        case elderName = "elder_name"
        case triggeredAt = "triggered_at"
    }
}

struct MedsResponse: Codable {
    let status: String
    let data: [Medication]
}

struct Medication: Codable, Identifiable {
    let id: String
    let elderId: String
    let medName: String
    let remindTime: String
    var isAdministered: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case elderId = "elder_id"
        case medName = "med_name"
        case remindTime = "remind_time"
        case isAdministered = "is_administered"
    }
}

class APIService: ObservableObject {
    @Published var elders: [Elder] = []
    @Published var activeAlerts: [ElderAlert] = []
    @Published var medications: [Medication] = []
    
    private let baseURL = "https://coral-app-f89y5.ondigitalocean.app/api"
    private var timer: Timer?
    
    // 用於回呼警報通知
    var onNewAlertTriggered: ((ElderAlert) -> Void)?
    
    init() {
        startPolling()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startPolling() {
        fetchData()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchData()
        }
    }
    
    func fetchData() {
        fetchElders()
        fetchAlerts()
        fetchMedications()
    }
    
    func fetchElders() {
        guard let url = URL(string: "\(baseURL)/admin/elders/location") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(ElderLocationResponse.self, from: data)
                DispatchQueue.main.async {
                    self.elders = response.data
                }
            } catch {
                print("解碼 Elders 失敗:", error)
            }
        }.resume()
    }
    
    func fetchAlerts() {
        guard let url = URL(string: "\(baseURL)/admin/alerts") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(AlertResponse.self, from: data)
                DispatchQueue.main.async {
                    let oldPendingCount = self.activeAlerts.filter { $0.status == "pending" }.count
                    self.activeAlerts = response.data
                    
                    let newPendingAlerts = response.data.filter { $0.status == "pending" }
                    if newPendingAlerts.count > oldPendingCount, let latest = newPendingAlerts.first {
                        // 觸發警報通知回呼
                        self.onNewAlertTriggered?(latest)
                    }
                }
            } catch {
                print("解碼 Alerts 失敗:", error)
            }
        }.resume()
    }
    
    func fetchMedications() {
        guard let url = URL(string: "\(baseURL)/admin/meds/today") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(MedsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.medications = response.data
                }
            } catch {
                print("解碼 Meds 失敗:", error)
            }
        }.resume()
    }
    
    // 確認/解除警報
    func confirmAlert(alertId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/admin/alerts/\(alertId)/confirm") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            DispatchQueue.main.async {
                if success {
                    self.fetchData()
                }
                completion(success)
            }
        }.resume()
    }
    
    // 標記用藥確認
    func toggleMedication(medId: String, isAdministered: Bool) {
        guard let url = URL(string: "\(baseURL)/admin/meds/\(medId)/check") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["isAdministered": isAdministered]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                self.fetchMedications()
            }
        }.resume()
    }
}
