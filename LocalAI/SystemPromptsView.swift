import SwiftUI
import SwiftData

struct SystemPromptsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SystemPrompt.timestamp, order: .reverse) private var allPrompts: [SystemPrompt]

    @State private var newTitle = ""
    @State private var newContent = ""
    @State private var showingAdd = false
    @State private var editingPrompt: SystemPrompt?
    @State private var showingEdit = false

    var prompts: [SystemPrompt] {
        allPrompts.filter { !$0.isHidden }
    }

    var body: some View {
        List {
            ForEach(prompts) { prompt in
                VStack(alignment: .leading) {
                    Text(prompt.title).font(.headline)
                    Text(prompt.content).font(.subheadline).foregroundColor(.gray)
                }
                .contextMenu {
                    Button("Edit") {
                        editingPrompt = prompt
                        newTitle = prompt.title
                        newContent = prompt.content
                        showingEdit = true
                    }
                    Button("Delete", role: .destructive) {
                        deletePrompt(prompt)
                    }
                }
            }
            .onDelete(perform: deletePrompts)
        }
        .navigationTitle("System Prompts")
        .toolbar {
            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationView {
                Form {
                    TextField("Title", text: $newTitle)
                    TextEditor(text: $newContent)
                        .frame(height: 200)
                }
                .navigationTitle("New Prompt")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAdd = false
                            clearForm()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            addPrompt()
                            showingAdd = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit, onDismiss: clearForm) {
            NavigationView {
                Form {
                    TextField("Title", text: $newTitle)
                    TextEditor(text: $newContent)
                        .frame(height: 200)
                }
                .navigationTitle("Edit Prompt")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingEdit = false
                            clearForm()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            updatePrompt()
                            showingEdit = false
                        }
                    }
                }
            }
        }
    }

    func addPrompt() {
        guard !newTitle.isEmpty, !newContent.isEmpty else { return }
        let prompt = SystemPrompt(title: newTitle, content: newContent)
        context.insert(prompt)
        try? context.save()
        clearForm()
    }

    func updatePrompt() {
        guard let p = editingPrompt,
              !newTitle.isEmpty, !newContent.isEmpty else { return }
        p.title = newTitle
        p.content = newContent
        try? context.save()
        clearForm()
    }

    func deletePrompt(_ prompt: SystemPrompt) {
        context.delete(prompt)
        try? context.save()
    }

    func deletePrompts(at offsets: IndexSet) {
        for index in offsets {
            context.delete(prompts[index])
        }
        try? context.save()
    }

    func clearForm() {
        newTitle = ""
        newContent = ""
        editingPrompt = nil
    }
}
