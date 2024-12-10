import SwiftUI
import SwiftData

struct SystemPromptSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let chat: Chat
    let onSelectionComplete: () -> Void

    @Query(sort: \SystemPrompt.timestamp, order: .reverse) private var allPrompts: [SystemPrompt]

    var prompts: [SystemPrompt] {
        allPrompts.filter { !$0.isHidden }
    }

    var body: some View {
        NavigationView {
            List {
                Button("Clear System Prompt") {
                    chat.systemPromptID = nil
                    try? context.save()
                    dismiss()
                    onSelectionComplete()
                }

                ForEach(prompts) { prompt in
                    Button(prompt.title) {
                        chat.systemPromptID = prompt.id
                        try? context.save()
                        dismiss()
                        onSelectionComplete()
                    }
                }
            }
            .navigationTitle("Select Prompt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
