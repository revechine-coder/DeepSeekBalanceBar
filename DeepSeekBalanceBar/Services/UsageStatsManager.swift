import Foundation

/// 基于余额变化估算本月和历史累计消费。
///
/// DeepSeek 目前未提供消费金额 API；这里以每次刷新后的余额下降额作为消费增量。
final class UsageStatsManager {
    static let shared = UsageStatsManager()

    private let defaults: UserDefaults
    private let lastBalancesKey = "usage-stats-last-balances"
    private let monthlySpendKey = "usage-stats-monthly-spend"
    private let historicalSpendKey = "usage-stats-historical-spend"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func update(with balanceInfos: [BalanceInfo], at date: Date = Date()) -> UsageStatsSnapshot {
        var lastBalances = decimalDictionary(forKey: lastBalancesKey)
        var monthlySpend = decimalDictionary(forKey: monthlyStorageKey(for: date))
        var historicalSpend = decimalDictionary(forKey: historicalSpendKey)

        for balanceInfo in balanceInfos {
            guard let currentBalance = Decimal(string: balanceInfo.totalBalance) else {
                continue
            }

            let currency = balanceInfo.currency

            if let previousBalance = lastBalances[currency], previousBalance > currentBalance {
                let spent = previousBalance - currentBalance
                monthlySpend[currency, default: 0] += spent
                historicalSpend[currency, default: 0] += spent
            }

            lastBalances[currency] = currentBalance
        }

        setDecimalDictionary(lastBalances, forKey: lastBalancesKey)
        setDecimalDictionary(monthlySpend, forKey: monthlyStorageKey(for: date))
        setDecimalDictionary(historicalSpend, forKey: historicalSpendKey)

        return snapshot(for: date)
    }

    func snapshot(for date: Date = Date()) -> UsageStatsSnapshot {
        UsageStatsSnapshot(
            monthlySpend: decimalDictionary(forKey: monthlyStorageKey(for: date)),
            historicalSpend: decimalDictionary(forKey: historicalSpendKey)
        )
    }

    private func monthlyStorageKey(for date: Date) -> String {
        "\(monthlySpendKey)-\(Self.monthFormatter.string(from: date))"
    }

    private func decimalDictionary(forKey key: String) -> [String: Decimal] {
        guard let stored = defaults.dictionary(forKey: key) as? [String: String] else {
            return [:]
        }

        return stored.reduce(into: [String: Decimal]()) { result, item in
            if let value = Decimal(string: item.value) {
                result[item.key] = value
            }
        }
    }

    private func setDecimalDictionary(_ dictionary: [String: Decimal], forKey key: String) {
        let stored = dictionary.mapValues { NSDecimalNumber(decimal: $0).stringValue }
        defaults.set(stored, forKey: key)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()
}

struct UsageStatsSnapshot {
    let monthlySpend: [String: Decimal]
    let historicalSpend: [String: Decimal]

    static let empty = UsageStatsSnapshot(monthlySpend: [:], historicalSpend: [:])
}
