import SwiftUI
import SwiftData

@main
struct LocalAIApp: App {
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataController.container)
        }
    }
}
