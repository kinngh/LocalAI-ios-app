//
//  MessageBubbleView.swift
//  LocalAI
//
//  Created by Kinngh Heura on 10/12/2024.
//


import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let fontSize: Double

    var body: some View {
        HStack {
            if message.role == "assistant" {
                // Assistant on the left (green)
                VStack(alignment: .leading) {
                    Text(message.content)
                        .font(.system(size: fontSize))
                        .padding(8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
            } else {
                // User on the right (blue)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message.content)
                        .font(.system(size: fontSize))
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
    }
}