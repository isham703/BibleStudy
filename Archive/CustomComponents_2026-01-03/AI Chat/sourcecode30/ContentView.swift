//
//  ContentView.swift
//  sourcecode30
//
//  Created by M.Damra on 29.01.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AIChatView()
    }
}

#Preview {
    ContentView()
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct TypingIndicator: View {
    @State private var dotScale: [CGFloat] = [0.5, 0.7, 0.5]
    var body: some View {
        HStack {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale[index])
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2),value: dotScale[index])
            }
        }
        .onAppear {
            dotScale = [1.2, 0.8, 1.2]
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.text)
                .padding()
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct AIChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .transition(.asymmetric(
                                insertion: .move(edge: message.isUser ? .trailing : .leading),
                                removal: .opacity
                            ))
                    }

                    if isLoading {
                        TypingIndicator()
                    }
                }
                .padding()
            }

            HStack {
                TextField("Ask me anything...", text: $inputText)
                    .textFieldStyle(.roundedBorder)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .padding(10)
                        .background(Circle().fill(Color.blue))
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func sendMessage() {
        withAnimation {
            let newMessage = ChatMessage(text: inputText, isUser: true)
            messages.append(newMessage)
            inputText = ""
            isLoading = true
        }

        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                let response = ChatMessage(text: "Hi! I'm fine. How are you, bro?", isUser: false)
                messages.append(response)
                isLoading = false
            }
        }
    }
} 
