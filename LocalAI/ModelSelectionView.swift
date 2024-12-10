import SwiftUI

struct ModelSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Binding var selectedModel: String
    let baseURL: String

    @State private var models: [LMStudioModel] = []
    @State private var loading = false
    @State private var errorMessage: String?

    let chat: Chat

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("Loading...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                } else {
                    List(models, id: \.id) { model in
                        Button(model.id) {
                            selectedModel = model.id
                            chat.modelID = model.id
                            try? context.save()
                            // Insert a system log message (not sent to LLM)
                            let msg = ChatMessage(chatID: chat.id, role: "system", content: "Model changed to: \(model.id)", timestamp: Date(), sendToLLM: false)
                            context.insert(msg)
                            try? context.save()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadModels()
            }
        }
    }

    func loadModels() {
        loading = true
        Task {
            do {
                let net = NetworkManager()
                let result = try await net.fetchModels(baseURL: baseURL)
                await MainActor.run {
                    self.models = result
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.loading = false
                }
            }
        }
    }
}
