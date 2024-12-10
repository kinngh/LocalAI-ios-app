import SwiftUI
import SwiftData

struct ChatDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [Settings]
    @Query(sort: \SystemPrompt.timestamp, order: .reverse) private var allPrompts: [SystemPrompt]

    let chat: Chat
    @State private var inputText = ""
    @State private var isModelSelectionPresented = false
    @State private var editingMessage: ChatMessage? = nil
    @State private var isSystemPromptSelectionPresented = false
    @State private var renameAlert = false
    @State private var newTitle = ""
    @State private var streamingContent = ""

    @Query private var messages: [ChatMessage]

    init(chat: Chat) {
        self.chat = chat
        let chatID = chat.id
        _messages = Query(
            filter: #Predicate<ChatMessage> { $0.chatID == chatID },
            sort: \.timestamp,
            order: .forward
        )
    }

    var settings: Settings {
        settingsList.first ?? Settings()
    }

    var selectedSystemPrompt: SystemPrompt? {
        guard let id = chat.systemPromptID else { return nil }
        return allPrompts.first(where: { $0.id == id })
    }

    var systemPromptMessage: ChatMessage? {
        messages.first(where: { $0.role == "system" && $0.sendToLLM == true })
    }

    var canSend: Bool {
        guard selectedSystemPrompt != nil, (chat.modelID?.isEmpty == false) else {
            return false
        }
        return true
    }

    var displayedMessages: [ChatMessage] {
        messages
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(displayedMessages) { msg in
                        MessageBubbleView(message: msg, fontSize: settings.fontSize)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .contextMenu {
                                Button("Edit") {
                                    editingMessage = msg
                                }
                                Button("Delete", role: .destructive) {
                                    deleteMessage(msg)
                                }
                            }
                    }

                    if !streamingContent.isEmpty {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(streamingContent)
                                    .font(.system(size: settings.fontSize))
                                    .padding(8)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
                .padding(.bottom, 50)
            }

            HStack {
                TextField("Enter message", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    Task {
                        await sendMessage()
                    }
                }
                .disabled(!canSend)
            }
            .padding()
        }
        .navigationTitle(chat.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Model") {
                        isModelSelectionPresented = true
                    }
                    Button("Prompt") {
                        isSystemPromptSelectionPresented = true
                    }
                    Button("Rename") {
                        newTitle = chat.title
                        renameAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $editingMessage) { message in
            ChatMessageEditorView(message: message)
        }
        .sheet(isPresented: $isModelSelectionPresented) {
            ModelSelectionView(selectedModel: .constant(chat.modelID ?? ""), baseURL: settings.serverURL, chat: chat)
        }
        .sheet(isPresented: $isSystemPromptSelectionPresented) {
            SystemPromptSelectionView(chat: chat) {
                applySystemPromptChange()
            }
        }
        .alert("Rename Chat", isPresented: $renameAlert, actions: {
            TextField("Chat Title", text: $newTitle)
            Button("OK") {
                chat.title = newTitle
                try? context.save()
            }
            Button("Cancel", role: .cancel) {}
        })
        .onAppear {
            ensureDefaultPrompt()
        }
    }

    func ensureDefaultPrompt() {
        if chat.systemPromptID == nil {
            // Pick fallback or first prompt
            if let p = allPrompts.first {
                chat.systemPromptID = p.id
                try? context.save()
                setSystemPromptMessage(p.content)
            }
        } else if let sp = selectedSystemPrompt {
            // Ensure there's a system prompt message reflecting the current prompt
            if systemPromptMessage == nil {
                setSystemPromptMessage(sp.content)
            } else if systemPromptMessage?.content != sp.content {
                systemPromptMessage?.content = sp.content
                try? context.save()
            }
        }
    }

    func applySystemPromptChange() {
        // When prompt changes, update the existing system prompt message to the new prompt.
        if let sp = selectedSystemPrompt {
            if let sm = systemPromptMessage {
                sm.content = sp.content
                try? context.save()
            } else {
                setSystemPromptMessage(sp.content)
            }
            // Insert a system message note for user reference if desired:
            insertSystemChangeMessage("System prompt changed to: \(sp.title)")
        } else {
            // No prompt selected, remove system prompt message
            if let sm = systemPromptMessage {
                context.delete(sm)
                try? context.save()
            }
            insertSystemChangeMessage("System prompt cleared.")
        }
    }

    func setSystemPromptMessage(_ content: String) {
        // One true system prompt message that will be sent to LLM
        let systemMsg = ChatMessage(chatID: chat.id, role: "system", content: content, timestamp: Date(timeIntervalSince1970: 0), sendToLLM: true)
        context.insert(systemMsg)
        try? context.save()
    }

    func insertSystemChangeMessage(_ text: String) {
        // This message is NOT to be sent to LLM
        let msg = ChatMessage(chatID: chat.id, role: "system", content: text, timestamp: Date(), sendToLLM: false)
        context.insert(msg)
        try? context.save()
    }

    func deleteMessage(_ msg: ChatMessage) {
        // If deleting the main system prompt message, also clear systemPromptID
        if msg.role == "system" && msg.sendToLLM {
            chat.systemPromptID = nil
        }
        context.delete(msg)
        try? context.save()
    }

    func sendMessage() async {
        guard canSend else { return }

        let network = NetworkManager()

        // Filter messages to send:
        // - Include one system prompt message with sendToLLM = true
        // - Include all user/assistant messages
        var fullMessages: [LMStudioChatMessage] = messages
            .filter { $0.role != "system" || $0.sendToLLM == true }
            .map { LMStudioChatMessage(role: $0.role, content: $0.content) }

        let userInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userInput.isEmpty {
            let userMsg = ChatMessage(chatID: chat.id, role: "user", content: userInput, timestamp: Date(), sendToLLM: true)
            context.insert(userMsg)
            try? context.save()
            fullMessages.append(LMStudioChatMessage(role: "user", content: userInput))
        }

        inputText = ""
        streamingContent = ""

        let model = chat.modelID ?? ""
        let request = LMStudioChatRequest(model: model, messages: fullMessages, max_tokens: 256, temperature: 0.7, stream: true)

        do {
            for try await chunk in network.streamChatCompletionRequest(baseURL: settings.serverURL, request: request) {
                await MainActor.run {
                    streamingContent += chunk
                }
            }

            if !streamingContent.isEmpty {
                let assistantMsg = ChatMessage(chatID: chat.id, role: "assistant", content: streamingContent, timestamp: Date(), sendToLLM: true)
                context.insert(assistantMsg)
                try? context.save()
                streamingContent = ""
            }
        } catch {
            print("Error: \(error)")
        }
    }
}
