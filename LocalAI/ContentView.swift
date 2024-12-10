import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]
    @Query(sort: \SystemPrompt.timestamp, order: .reverse) private var prompts: [SystemPrompt]
    @Query private var settingsList: [Settings]

    var body: some View {
        NavigationView {
            VStack {
                if chats.isEmpty {
                    VStack {
                        Text("No chats. Create one.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                } else {
                    ChatsListView(chats: chats)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Settings") {
                            showSettings = true
                        }
                        Button("Prompts") {
                            showPrompts = true
                        }
                    } label: {
                        Image(systemName: "line.horizontal.3")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addChat) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("Local AI")
            .onAppear {
                // Ensure settings
                if settingsList.isEmpty {
                    let s = Settings()
                    context.insert(s)
                    try? context.save()
                }

                // Ensure fallback prompt if none
                if prompts.isEmpty {
                    let fallback = SystemPrompt(title: "Default Prompt",
                                               content: "You're LocalAI, a helpful assistant",
                                               isHidden: true)
                    context.insert(fallback)
                    try? context.save()
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                        .navigationBarTitle("Settings", displayMode: .inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showSettings = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showPrompts) {
                NavigationView {
                    SystemPromptsView()
                        .navigationBarTitle("System Prompts", displayMode: .inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showPrompts = false
                                }
                            }
                        }
                }
            }
        }
    }

    @State private var showSettings = false
    @State private var showPrompts = false

    func addChat() {
        let newChat = Chat(title: "New Chat \(Date().formatted())")
        
        // Set default prompt if none selected
        if let prompt = prompts.first { // first is fallback or user-defined?
            newChat.systemPromptID = prompt.id
        }
        
        context.insert(newChat)
        try? context.save()

        // Insert a system message indicating prompt selected
        if let spID = newChat.systemPromptID,
           let sp = prompts.first(where: { $0.id == spID }) {
            let msg = ChatMessage(chatID: newChat.id, role: "system", content: "System prompt selected: \(sp.title)", timestamp: Date())
            context.insert(msg)
        }

        try? context.save()
    }
}
