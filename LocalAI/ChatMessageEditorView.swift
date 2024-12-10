import SwiftUI
import SwiftData

struct ChatMessageEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State var editedContent: String
    let message: ChatMessage

    init(message: ChatMessage) {
        self.message = message
        _editedContent = State(initialValue: message.content)
    }

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $editedContent)
                    .padding()
            }
            .navigationTitle("Edit Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        message.content = editedContent
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
