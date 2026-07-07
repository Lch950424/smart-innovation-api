import Foundation
import AVFoundation
import AudioToolbox

class SoundManager {
    static let shared = SoundManager()
    private var timer: Timer?
    private var isPlaying = false
    
    func startAlarm() {
        guard !isPlaying else { return }
        isPlaying = true
        
        // 每 1.2 秒循環播放 iOS 內建警報/系統提示音 (ID: 1005 類似警笛或警告)
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            // 播放警告音
            AudioServicesPlaySystemSound(1005)
            // 同時觸發手機震動 (Vibration)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    func stopAlarm() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }
}
