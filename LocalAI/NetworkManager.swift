import Foundation

struct LMStudioModel: Codable {
    let id: String
    let object: String
    let owned_by: String
}

struct LMStudioModelsResponse: Codable {
    let data: [LMStudioModel]
}

struct LMStudioChatMessage: Codable {
    let role: String
    let content: String
}

struct LMStudioChatRequest: Codable {
    let model: String
    let messages: [LMStudioChatMessage]
    let max_tokens: Int
    let temperature: Double
    let stream: Bool
}

struct LMStudioChatCompletionChunk: Codable {
    let choices: [ChunkChoice]

    struct ChunkChoice: Codable {
        let delta: LMStudioChatMessageDelta?
        let finish_reason: String?
    }
}

struct LMStudioChatMessageDelta: Codable {
    let role: String?
    let content: String?
}

struct LMStudioChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: LMStudioChatMessage
    }
}

struct LMStudioCompletionRequest: Codable {
    let model: String
    let prompt: String
    let max_tokens: Int
    let temperature: Double
}

struct LMStudioCompletionResponse: Codable {
    let choices: [TextChoice]

    struct TextChoice: Codable {
        let text: String
    }
}

class NetworkManager: ObservableObject {
    func fetchModels(baseURL: String) async throws -> [LMStudioModel] {
        guard let url = URL(string: "\(baseURL)/v1/models") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(LMStudioModelsResponse.self, from: data)
        return response.data
    }

    func sendChatCompletionRequest(baseURL: String, request: LMStudioChatRequest) async throws -> LMStudioChatCompletionResponse {
        // Non-streaming call (if needed elsewhere)
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(request)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(LMStudioChatCompletionResponse.self, from: data)
    }

    func sendCompletionRequest(baseURL: String, request: LMStudioCompletionRequest) async throws -> LMStudioCompletionResponse {
        guard let url = URL(string: "\(baseURL)/v1/completions") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(request)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(LMStudioCompletionResponse.self, from: data)
    }

    // New: Streaming request
    func streamChatCompletionRequest(baseURL: String, request: LMStudioChatRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
                        throw URLError(.badURL)
                    }
                    var req = URLRequest(url: url)
                    req.httpMethod = "POST"
                    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.httpBody = try JSONEncoder().encode(request)

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }

                    // The stream should return data line-by-line
                    for try await line in bytes.lines {
                        // Each line may look like: `data: { ... }`
                        // Ignore empty lines or lines starting with "data: "
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard trimmed.hasPrefix("data:") else {
                            continue
                        }

                        let jsonString = trimmed.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
                        if jsonString == "[DONE]" {
                            // End of stream
                            break
                        }

                        // Parse chunk
                        if let data = jsonString.data(using: .utf8) {
                            let chunk = try JSONDecoder().decode(LMStudioChatCompletionChunk.self, from: data)
                            // Extract content from delta if available
                            for choice in chunk.choices {
                                if let content = choice.delta?.content {
                                    continuation.yield(content)
                                }
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
