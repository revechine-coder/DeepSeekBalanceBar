import Foundation

/// 管理 DeepSeek API Key 的本地保存。
///
/// 这里使用 UserDefaults，避免 macOS Keychain 在启动或读取时弹出系统密码确认。
/// 轻量菜单栏工具可以获得更顺滑的启动体验；如果未来需要更高安全等级，再切回 Keychain。
final class KeychainManager {
    static let shared = KeychainManager()

    private let storageKey = "deepseek-api-key"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    static func normalizedAPIKey(_ apiKey: String) -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedKey.lowercased().hasPrefix("bearer ") {
            return String(trimmedKey.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return trimmedKey
    }

    func saveAPIKey(_ apiKey: String) throws {
        let trimmedKey = Self.normalizedAPIKey(apiKey)

        guard !trimmedKey.isEmpty else {
            throw APIKeyStorageError.emptyValue
        }

        defaults.set(trimmedKey, forKey: storageKey)
    }

    func saveAPIKeyWithStatus(_ apiKey: String) -> APIKeyStorageStatus {
        do {
            try saveAPIKey(apiKey)
            return .success("API Key 已保存")
        } catch {
            return .failure(error)
        }
    }

    func loadAPIKey() -> String? {
        defaults.string(forKey: storageKey)
    }

    func loadAPIKeyWithStatus() -> APIKeyLoadResult {
        guard let apiKey = loadAPIKey(), !apiKey.isEmpty else {
            return APIKeyLoadResult(apiKey: nil, status: .notFound)
        }

        return APIKeyLoadResult(apiKey: apiKey, status: .success("API Key 已读取"))
    }

    func deleteAPIKey() {
        defaults.removeObject(forKey: storageKey)
    }

    func deleteAPIKeyWithStatus() -> APIKeyStorageStatus {
        deleteAPIKey()
        return .success("API Key 已删除")
    }

    func diagnosticSummary(for status: APIKeyStorageStatus) -> String {
        "本地保存：\(status.message)"
    }
}

struct APIKeyLoadResult {
    let apiKey: String?
    let status: APIKeyStorageStatus
}

enum APIKeyStorageStatus {
    case success(String)
    case notFound
    case failure(Error)

    var message: String {
        switch self {
        case .success(let message):
            return message
        case .notFound:
            return "未找到已保存的 API Key"
        case .failure(let error):
            return error.localizedDescription
        }
    }
}

enum APIKeyStorageError: LocalizedError {
    case emptyValue

    var errorDescription: String? {
        switch self {
        case .emptyValue:
            return "API Key 不能为空。"
        }
    }
}
