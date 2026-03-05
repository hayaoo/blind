import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("reminderInterval") private var reminderInterval = 30
    @AppStorage("eyeCloseDuration") private var eyeCloseDuration = 5
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        Form {
            Section {
                Picker("リマインド間隔", selection: $reminderInterval) {
                    Text("15分").tag(15)
                    Text("30分").tag(30)
                    Text("45分").tag(45)
                    Text("60分").tag(60)
                }

                Picker("目を閉じる時間", selection: $eyeCloseDuration) {
                    Text("3秒").tag(3)
                    Text("5秒").tag(5)
                    Text("10秒").tag(10)
                }
            }

            Section {
                Toggle("サウンド", isOn: $soundEnabled)
                Toggle("ログイン時に起動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLogin.setEnabled(newValue)
                    }
            }

            Section {
                Button("チュートリアルを再表示") {
                    UserDefaults.standard.set(false, forKey: "onboardingCompleted")
                    // AppDelegateのstartOnboardingを呼ぶ
                    if let delegate = NSApp.delegate as? AppDelegate {
                        delegate.startOnboardingFromSettings()
                    }
                }
            }

            Section {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 250)
        .navigationTitle("設定")
    }
}

enum LaunchAtLogin {
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}
