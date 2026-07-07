import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject var apiService = APIService()
    @State private var showingAlertBanner = false
    @State private var currentAlert: ElderAlert?
    
    var body: some View {
        TabView {
            // Tab 1: 儀表板 & 即時警報
            DashboardView(apiService: apiService, currentAlert: $currentAlert)
                .tabItem {
                    Label("監控看板", systemImage: "shield.righthalf.filled")
                }
            
            // Tab 2: 長者地圖定位
            LiveMapView(apiService: apiService)
                .tabItem {
                    Label("即時定位", systemImage: "map.fill")
                }
            
            // Tab 3: 今日用藥確認
            MedicationListView(apiService: apiService)
                .tabItem {
                    Label("用藥管理", systemImage: "pills.fill")
                }
        }
        .tint(.indigo)
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            
            // 綁定警報觸發回呼
            apiService.onNewAlertTriggered = { alert in
                self.currentAlert = alert
                SoundManager.shared.startAlarm()
                NotificationManager.shared.sendLocalNotification(
                    title: "⚠️ 電子圍籬警報！",
                    body: "\(alert.elderName) 已經超出安全圍籬區域！"
                )
            }
        }
    }
}

// ==========================================
// 1. 監控儀表板 View
// ==========================================
struct DashboardView: View {
    @ObservedObject var apiService: APIService
    @Binding var currentAlert: ElderAlert?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 長者當前狀態狀態卡
                    if let elder = apiService.elders.first {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("被照護者狀態")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(elder.name)
                                    .font(.title2)
                                    .bold()
                            }
                            Spacer()
                            
                            StatusBadge(status: elder.status)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // 出界警報卡片
                    if let alert = apiService.activeAlerts.first(where: { $0.status == "pending" }) {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.title)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("⚠️ 電子圍籬警告")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Text("\(alert.elderName) 已超出機構圍籬範圍！")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                            
                            Button(action: {
                                apiService.confirmAlert(alertId: alert.id) { success in
                                    if success {
                                        SoundManager.shared.stopAlarm()
                                        currentAlert = nil
                                    }
                                }
                            }) {
                                Text("確認安全並解除警報")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 2)
                        )
                        .cornerRadius(12)
                    } else {
                        // 安全提示卡
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 50))
                            Text("目前一切安全")
                                .font(.headline)
                            Text("所有長者皆在電子圍籬保護範圍之內。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // 警報歷史日誌
                    VStack(alignment: .leading, spacing: 10) {
                        Text("警報歷史記錄")
                            .font(.headline)
                        
                        if apiService.activeAlerts.isEmpty {
                            Text("無任何警報記錄")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(apiService.activeAlerts) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.elderName)
                                            .font(.subheadline)
                                            .bold()
                                        Text(formatTime(item.triggeredAt))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(item.status == "pending" ? "處理中" : "已確認")
                                        .font(.caption)
                                        .bold()
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(item.status == "pending" ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                                        .foregroundColor(item.status == "pending" ? .red : .green)
                                        .cornerRadius(6)
                                }
                                .padding(.vertical, 8)
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("照護監控面板")
        }
    }
    
    func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else { return isoString }
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return timeFormatter.string(from: date)
    }
}

// 狀態徽章元件
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .cornerRadius(8)
    }
    
    var statusText: String {
        switch status {
        case "normal": return "正常範圍"
        case "out_of_bounds": return "⚠️ 警報出界"
        case "on_leave": return "🛌 請假中"
        case "outing": return "🚗 外出中"
        default: return status
        }
    }
    
    var badgeColor: Color {
        switch status {
        case "normal": return .green
        case "out_of_bounds": return .red
        case "on_leave": return .blue
        case "outing": return .blue
        default: return .gray
        }
    }
}

// ==========================================
// 2. 地圖定位 View
// ==========================================
struct LiveMapView: View {
    @ObservedObject var apiService: APIService
    
    // 預設台北 101 中心地圖區域
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0339, longitude: 121.5644),
        span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
    )
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: apiService.elders) { elder in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: elder.latitude, longitude: elder.longitude)) {
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(elder.status == "out_of_bounds" ? .red : (elder.status == "normal" ? .green : .blue))
                            .background(Color.white)
                            .clipShape(Circle())
                        Text(elder.name)
                            .font(.caption)
                            .bold()
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(6)
                    }
                }
            }
            .navigationTitle("實時定位圖")
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// ==========================================
// 3. 用藥提醒確認 View
// ==========================================
struct MedicationListView: View {
    @ObservedObject var apiService: APIService
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("今日需確認的用藥行程")) {
                    if apiService.medications.isEmpty {
                        Text("無藥物提醒排程")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(apiService.medications) { med in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(med.medName)
                                        .font(.headline)
                                        .strikethrough(med.isAdministered)
                                        .foregroundColor(med.isAdministered ? .secondary : .primary)
                                    Text("提醒時間：\(med.remindTime)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Button(action: {
                                    apiService.toggleMedication(medId: med.id, isAdministered: !med.isAdministered)
                                }) {
                                    HStack {
                                        Image(systemName: med.isAdministered ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(med.isAdministered ? .green : .gray)
                                        Text(med.isAdministered ? "已餵藥" : "確認餵藥")
                                            .font(.subheadline)
                                            .foregroundColor(med.isAdministered ? .green : .primary)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(med.isAdministered ? .green : .indigo)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("用藥餵藥清單")
        }
    }
}
