import Foundation
import Combine

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
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, latitude, longitude
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
    let isAdministered: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case elderId = "elder_id"
        case medName = "med_name"
        case remindTime = "remind_time"
        case isAdministered = "is_administered"
    }
}

class APIService: ObservableObject {
    @Published var elderName: String = "王大爺"
    @Published var elderStatus: String = "normal"
    @Published var medications: [Medication] = []
    
    private let baseURL = "https://coral-app-f89y5.ondigitalocean.app/api"
    private let elderId = "elder-01"
    private var timer: Timer?
    
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
        fetchElderStatus()
        fetchMedications()
    }
    
    func fetchElderStatus() {
        guard let url = URL(string: "\(baseURL)/admin/elders/location") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(ElderLocationResponse.self, from: data)
                if let elder = response.data.first(where: { $0.id == self.elderId }) {
                    DispatchQueue.main.async {
                        self.elderName = elder.name
                        self.elderStatus = elder.status
                    }
                }
            } catch {
                print("家屬端解碼 Elders 失敗:", error)
            }
        }.resume()
    }
    
    func fetchMedications() {
        guard let url = URL(string: "\(baseURL)/family/meds") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(MedsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.medications = response.data
                }
            } catch {
                print("家屬端解碼 Meds 失敗:", error)
            }
        }.resume()
    }
    
    // 設定請假與外出狀態
    func setLeaveStatus(type: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/family/leave") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "elderId": elderId,
            "type": type
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            DispatchQueue.main.async {
                if success {
                    self.fetchElderStatus()
                }
                completion(success)
            }
        }.resume()
    }
    
    // 新增用藥提醒
    func addMedication(medName: String, remindTime: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/family/meds") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "elderId": elderId,
            "medName": medName,
            "remindTime": remindTime
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 201 && error == nil
            DispatchQueue.main.async {
                if success {
                    self.fetchMedications()
                }
                completion(success)
            }
        }.resume()
    }
}
