import Foundation

/// API 使用量响应的通用模型，后续可根据 DeepSeek 官方接口字段继续细化。
struct UsageResponse: Codable {
    let totalTokens: Int?
    let promptTokens: Int?
    let completionTokens: Int?
    let startTime: Date?
    let endTime: Date?

    enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}
