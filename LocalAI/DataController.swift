import SwiftData
import Foundation

class DataController: ObservableObject {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Chat.self, ChatMessage.self, Settings.self, SystemPrompt.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
