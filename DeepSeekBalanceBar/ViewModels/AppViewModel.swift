import Foundation
import Combine

@available(macOS 14.0, *)
@MainActor
final class AppViewModel: ObservableObject {
    @Published var apiKeyInput = ""
    @Published var apiKey = ""
    @Published var balanceInfos: [BalanceInfo] = []
    @Published var isAvailable = false
    @Published var isLoading = false
    @Published var launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
    @Published var usageStats = UsageStatsSnapshot.empty
    @Published var errorMessage: String?
    @Published var keychainStatusMessage: String?
    @Published var lastUpdatedAt: Date?

    let refreshInterval: TimeInterval

    private let keychainManager: KeychainManager
    private let apiService: DeepSeekAPIService
    private let usageStatsManager: UsageStatsManager
    private var refreshTask: Task<Void, Never>?
    private var hasLoadedStoredAPIKey = false

    var isLoggedIn: Bool {
        !apiKey.isEmpty
    }

    var canSaveAPIKey: Bool {
        !apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var primaryBalanceText: String {
        guard let balanceInfo = balanceInfos.first else {
            return "--"
        }

        return "\(balanceInfo.currency) \(balanceInfo.totalBalance)"
    }

    var primaryCurrency: String {
        balanceInfos.first?.currency ?? "CNY"
    }

    var monthlySpendText: String {
        formattedAmount(usageStats.monthlySpend[primaryCurrency], currency: primaryCurrency)
    }

    var historicalSpendText: String {
        formattedAmount(usageStats.historicalSpend[primaryCurrency], currency: primaryCurrency)
    }

    init(
        keychainManager: KeychainManager = .shared,
        apiService: DeepSeekAPIService = DeepSeekAPIService(),
        usageStatsManager: UsageStatsManager = .shared,
        refreshInterval: TimeInterval = 60 * 60
    ) {
        self.keychainManager = keychainManager
        self.apiService = apiService
        self.usageStatsManager = usageStatsManager
        self.refreshInterval = refreshInterval
        self.usageStats = usageStatsManager.snapshot()
    }

    func loadStoredAPIKeyIfNeeded() {
        guard !hasLoadedStoredAPIKey else { return }

        hasLoadedStoredAPIKey = true
        loadStoredAPIKey()

        Task {
            try? await Task.sleep(for: .milliseconds(500))

            guard apiKey.isEmpty else { return }
            loadStoredAPIKey()
        }
    }

    func reloadStoredAPIKey() {
        loadStoredAPIKey()
    }

    func saveAPIKey() {
        let trimmedKey = KeychainManager.normalizedAPIKey(apiKeyInput)
        let status = keychainManager.saveAPIKeyWithStatus(trimmedKey)
        keychainStatusMessage = nil

        switch status {
        case .success:
            let verification = keychainManager.loadAPIKeyWithStatus()

            if verification.apiKey == trimmedKey {
                apiKey = trimmedKey
                apiKeyInput = ""
                keychainStatusMessage = "API Key 已保存"
                errorMessage = nil
                startAutoRefresh()

                Task {
                    await fetchData()
                }
            } else {
                keychainStatusMessage = keychainManager.diagnosticSummary(for: verification.status)
                errorMessage = "API Key 已保存，但立即读取校验失败。"
            }
        case .notFound:
            errorMessage = status.message
        case .failure:
            keychainStatusMessage = keychainManager.diagnosticSummary(for: status)
            errorMessage = status.message
        }
    }

    func fetchData() async {
        guard !apiKey.isEmpty else {
            errorMessage = "请先输入 DeepSeek API Key。"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.fetchBalance(apiKey: apiKey)
            usageStats = usageStatsManager.update(with: response.balanceInfos)
            balanceInfos = response.balanceInfos
            isAvailable = response.isAvailable
            lastUpdatedAt = Date()
            keychainStatusMessage = refreshedStatusMessage(for: response.balanceInfos)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        refreshTask?.cancel()
        refreshTask = nil

        let status = keychainManager.deleteAPIKeyWithStatus()
        keychainStatusMessage = nil

        if case .failure = status {
            keychainStatusMessage = keychainManager.diagnosticSummary(for: status)
            errorMessage = status.message
        }

        apiKey = ""
        apiKeyInput = ""
        balanceInfos = []
        isAvailable = false
        isLoading = false
        lastUpdatedAt = nil
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        do {
            try LaunchAtLoginManager.setEnabled(isEnabled)
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
            errorMessage = nil
        } catch {
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
            errorMessage = "开机启动设置失败：\(error.localizedDescription)"
        }
    }

    private func loadStoredAPIKey() {
        let result = keychainManager.loadAPIKeyWithStatus()
        keychainStatusMessage = nil

        guard let storedKey = result.apiKey, !storedKey.isEmpty else {
            if case .failure = result.status {
                keychainStatusMessage = keychainManager.diagnosticSummary(for: result.status)
                errorMessage = result.status.message
            }

            return
        }

        apiKey = storedKey
        apiKeyInput = ""
        keychainStatusMessage = "已读取保存的 API Key"
        errorMessage = nil
        startAutoRefresh()

        Task {
            await fetchData()
        }
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()

        refreshTask = Task { [weak self, refreshInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(refreshInterval))

                guard !Task.isCancelled else { return }
                guard let self else { return }
                await self.fetchData()
            }
        }
    }

    private func refreshedStatusMessage(for balanceInfos: [BalanceInfo]) -> String {
        guard !balanceInfos.isEmpty else {
            return "刷新成功，但接口未返回余额明细"
        }

        return "余额已刷新"
    }

    private func formattedAmount(_ amount: Decimal?, currency: String) -> String {
        let value = amount ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let number = NSDecimalNumber(decimal: value)
        let formattedValue = formatter.string(from: number) ?? "0.00"
        return "\(currency) \(formattedValue)"
    }
}
