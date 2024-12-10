import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [Settings]

    @State private var serverURL: String = ""
    @State private var fontSize: Double = 16.0

    var body: some View {
        Form {
            Section(header: Text("Server Settings")) {
                TextField("LMStudio Base URL", text: $serverURL)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Section(header: Text("Appearance")) {
                Slider(value: $fontSize, in: 10...30, step: 1) {
                    Text("Font Size")
                }
                Text("Font Size: \(Int(fontSize))")
            }

            Button("Save") {
                saveSettings()
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadSettings()
        }
    }

    func loadSettings() {
        if let s = settingsList.first {
            serverURL = s.serverURL
            fontSize = s.fontSize
        }
    }

    func saveSettings() {
        if let s = settingsList.first {
            s.serverURL = serverURL
            s.fontSize = fontSize
            try? context.save()
        }
    }
}
