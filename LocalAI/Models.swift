import Foundation
import SwiftData

@Model
class Settings {
    var id: UUID
    var serverURL: String
    var fontSize: Double

    init(id: UUID = UUID(), serverURL: String = "http://10.0.0.2:1234", fontSize: Double = 16.0) {
        self.id = id
        self.serverURL = serverURL
        self.fontSize = fontSize
    }
}

@Model
class Chat {
    var id: UUID
    var title: String
    var timestamp: Date
    var systemPromptID: UUID?
    var modelID: String?

    init(id: UUID = UUID(), title: String, timestamp: Date = Date(), systemPromptID: UUID? = nil, modelID: String? = nil) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.systemPromptID = systemPromptID
        self.modelID = modelID
    }
}

@Model
class ChatMessage {
    var id: UUID
    var chatID: UUID
    var role: String // "user", "assistant", or "system"
    var content: String
    var timestamp: Date
    var sendToLLM: Bool  // new property

    init(id: UUID = UUID(), chatID: UUID, role: String, content: String, timestamp: Date = Date(), sendToLLM: Bool = true) {
        self.id = id
        self.chatID = chatID
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.sendToLLM = sendToLLM
    }
}

@Model
class SystemPrompt {
    var id: UUID
    var title: String
    var content: String
    var timestamp: Date
    var isHidden: Bool // renamed from hidden

    init(id: UUID = UUID(), title: String, content: String, timestamp: Date = Date(), isHidden: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.timestamp = timestamp
        self.isHidden = isHidden
    }
}
