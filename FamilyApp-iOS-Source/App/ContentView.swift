import SwiftUI

struct ContentView: View {
    @StateObject var apiService = APIService()
    @State private var medNameInput = ""
    @State private var remindTimeInput = Date()
    @State private var showingAddSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 長者狀態區
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("👴 被照護長者")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(apiService.elderName)
                                    .font(.title2)
                                    .bold()
                                Text("狀態同步：\(Date().formatted(date: .omitted, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            StatusBadge(status: apiService.elderStatus)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // 請假與外出設定卡片
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🗓️ 請假與外出狀態設定")
                            .font(.headline)
                        
                        Text("當您帶長者回家休養或出門看診時，請開啟對應功能以「暫停電子圍籬警報」，防止系統向機構管理員持續報警。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        VStack(spacing: 10) {
                            Button(action: {
                                apiService.setLeaveStatus(type: "leave") { _ in }
                            }) {
                                HStack {
                                    Image(systemName: "bed.double.fill")
                                    Text("申請請假 (回家休養)")
                                }
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                apiService.setLeaveStatus(type: "outing") { _ in }
                            }) {
                                HStack {
                                    Image(systemName: "car.fill")
                                    Text("設定外出 (家人陪同)")
                                }
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.85))
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                apiService.setLeaveStatus(type: "cancel") { _ in }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("結束假單 (回歸機構監控)")
                                }
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.indigo)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.indigo.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.indigo, lineWidth: 1.5)
                                )
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // 新增用藥提醒表單
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💊 設定用藥提醒")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("藥物名稱")
                                    .font(.subheadline)
                                Spacer()
                                TextField("例如: 降血壓藥", text: $medNameInput)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                            }
                            
                            DatePicker("提醒時間", selection: $remindTimeInput, displayedComponents: .hourAndMinute)
                                .font(.subheadline)
                            
                            Button(action: {
                                let timeFormatter = DateFormatter()
                                timeFormatter.dateFormat = "HH:mm"
                                let timeString = timeFormatter.string(from: remindTimeInput)
                                
                                apiService.addMedication(medName: medNameInput, remindTime: timeString) { success in
                                    if success {
                                        medNameInput = ""
                                        showingAddSuccess = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            showingAddSuccess = false
                                        }
                                    }
                                }
                            }) {
                                Text("送出至機構提醒系統")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(medNameInput.isEmpty ? Color.gray : Color.indigo)
                                    .cornerRadius(8)
                            }
                            .disabled(medNameInput.isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .alert(isPresented: $showingAddSuccess) {
                        Alert(title: Text("設定成功"), message: Text("已將用藥行程發送至照護機構"), dismissButton: .default(Text("確定")))
                    }

                    // 用藥提醒列表
                    VStack(alignment: .leading, spacing: 10) {
                        Text("📋 用藥排程與機構餵食進度")
                            .font(.headline)
                        
                        if apiService.medications.isEmpty {
                            Text("目前無藥物提醒設定")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 10)
                        } else {
                            ForEach(apiService.medications) { med in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(med.medName)
                                            .font(.subheadline)
                                            .bold()
                                        Text("時間：\(med.remindTime)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: med.isAdministered ? "checkmark.circle.fill" : "hourglass")
                                            .foregroundColor(med.isAdministered ? .green : .purple)
                                        Text(med.isAdministered ? "機構已餵藥" : "等待餵藥中")
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(med.isAdministered ? .green : .purple)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(med.isAdministered ? Color.green.opacity(0.1) : Color.purple.opacity(0.1))
                                    .cornerRadius(6)
                                }
                                .padding(.vertical, 6)
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
            .navigationTitle("家屬遠端照護面板")
        }
    }
}

// 狀態徽章元件 (家屬端同步)
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
        case "normal": return "機構監控中"
        case "out_of_bounds": return "⚠️ 警報出界"
        case "on_leave": return "🛌 請假在家"
        case "outing": return "🚗 家屬外出"
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
