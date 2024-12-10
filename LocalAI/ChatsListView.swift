import SwiftUI
import SwiftData

struct ChatsListView: View {
    let chats: [Chat]
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            ForEach(chats) { chat in
                NavigationLink(destination: ChatDetailView(chat: chat)) {
                    Text(chat.title)
                }
            }
            .onDelete(perform: deleteChats)
        }
    }

    func deleteChats(at offsets: IndexSet) {
        for index in offsets {
            context.delete(chats[index])
        }
        try? context.save()
    }
}
