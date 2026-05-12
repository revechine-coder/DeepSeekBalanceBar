import Foundation

/// 封装 DeepSeek API 网络请求。
struct DeepSeekAPIService {
    private let baseURL = URL(string: "https://api.deepseek.com")!
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchBalance(apiKey: String) async throws -> BalanceResponse {
        let trimmedKey = KeychainManager.normalizedAPIKey(apiKey)

        guard !trimmedKey.isEmpty else {
            throw DeepSeekAPIError.missingAPIKey
        }

        let url = baseURL.appending(path: "user/balance")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)
            return try decoder.decode(BalanceResponse.self, from: data)
        } catch let error as DeepSeekAPIError {
            throw error
        } catch let error as DecodingError {
            throw DeepSeekAPIError.decodingFailed(error)
        } catch let error as URLError {
            throw DeepSeekAPIError.network(error)
        } catch {
            throw DeepSeekAPIError.unknown(error)
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw DeepSeekAPIError.unauthorized
        case 403:
            throw DeepSeekAPIError.forbidden
        case 429:
            throw DeepSeekAPIError.rateLimited
        case 500...599:
            throw DeepSeekAPIError.serverError(statusCode: httpResponse.statusCode)
        default:
            let message = String(data: data, encoding: .utf8)
            throw DeepSeekAPIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

enum DeepSeekAPIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case unauthorized
    case forbidden
    case rateLimited
    case serverError(statusCode: Int)
    case httpError(statusCode: Int, message: String?)
    case decodingFailed(DecodingError)
    case network(URLError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "请先输入 DeepSeek API Key。"
        case .invalidResponse:
            return "服务器响应格式异常。"
        case .unauthorized:
            return "API Key 无效或已过期。"
        case .forbidden:
            return "当前 API Key 没有访问余额接口的权限。"
        case .rateLimited:
            return "请求过于频繁，请稍后再试。"
        case .serverError:
            return "DeepSeek 服务暂时不可用，请稍后再试。"
        case .httpError(let statusCode, let message):
            if let message, !message.isEmpty {
                return "请求失败（\(statusCode)）：\(message)"
            }
            return "请求失败（HTTP \(statusCode)）。"
        case .decodingFailed:
            return "余额数据解析失败，可能是接口返回格式发生变化。"
        case .network(let error):
            return networkErrorDescription(error)
        case .unknown:
            return "发生未知错误，请稍后再试。"
        }
    }

    private func networkErrorDescription(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "网络连接失败，请检查网络后重试。"
        case .timedOut:
            return "请求超时，请稍后重试。"
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return "无法连接 DeepSeek 服务器。"
        case .secureConnectionFailed:
            return "安全连接失败，请检查系统网络环境。"
        default:
            return "网络请求失败：\(error.localizedDescription)"
        }
    }
}
