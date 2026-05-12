import AppKit
import SwiftUI

@available(macOS 14.0, *)
struct MainView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoggedIn {
                DashboardView(viewModel: viewModel)
            } else {
                LoginView(viewModel: viewModel)
            }
        }
        .frame(width: 288)
        .background(.clear)
        .task {
            viewModel.loadStoredAPIKeyIfNeeded()
            viewModel.refreshLaunchAtLoginStatus()
        }
    }
}

@available(macOS 14.0, *)
struct LoginView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppHeaderView(title: "DeepSeek Balance", subtitle: "保存 API Key 后自动刷新余额")

            VStack(alignment: .leading, spacing: 10) {
                Text("API Key")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                SecureField("sk-...", text: $viewModel.apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.saveAPIKey()
                    }
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            ErrorMessageView(message: viewModel.errorMessage)
            StatusMessageView(message: viewModel.keychainStatusMessage)

            VStack(spacing: 8) {
                Button {
                    viewModel.saveAPIKey()
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Text(viewModel.isLoading ? "保存中" : "保存并刷新")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSaveAPIKey)

                Button {
                    viewModel.reloadStoredAPIKey()
                } label: {
                    Label("重新读取已保存 Key", systemImage: "key")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
    }
}

@available(macOS 14.0, *)
struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BalanceSummaryCard(viewModel: viewModel)

            if viewModel.balanceInfos.count > 1 {
                VStack(spacing: 8) {
                    ForEach(viewModel.balanceInfos.dropFirst()) { balanceInfo in
                        BalanceRowView(balanceInfo: balanceInfo)
                    }
                }
            }

            ErrorMessageView(message: viewModel.errorMessage)
            StatusMessageView(message: viewModel.keychainStatusMessage)

            SubtleDivider()
                .padding(.horizontal, 8)

            DashboardActionBar(viewModel: viewModel)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.045))
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 16, x: 0, y: 8)
    }
}

@available(macOS 14.0, *)
struct BalanceSummaryCard: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("账户余额")
                    .font(.headline.weight(.semibold))

                Button {
                    Task { await viewModel.fetchData() }
                } label: {
                    InlineRefreshButton(isLoading: viewModel.isLoading)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .help(viewModel.isLoading ? "刷新中" : "刷新")

                Spacer()

                StatusPillView(
                    isLoading: viewModel.isLoading,
                    isAvailable: viewModel.isAvailable,
                    hasRefreshed: viewModel.lastUpdatedAt != nil || !viewModel.balanceInfos.isEmpty
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(primaryCurrency)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(primaryAmount)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SubtleDivider()

            HStack(spacing: 14) {
                SpendingMetricView(title: "本月消费", value: viewModel.monthlySpendText)
                SpendingMetricView(title: "历史累计", value: viewModel.historicalSpendText)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryCurrency: String {
        viewModel.primaryCurrency
    }

    private var primaryAmount: String {
        viewModel.balanceInfos.first?.totalBalance ?? "--"
    }
}

struct SpendingMetricView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)

            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(macOS 14.0, *)
struct DashboardActionBar: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isSettingsExpanded = false

    var body: some View {
        HStack(spacing: 0) {
            Button {
                openTopUpPage()
            } label: {
                FooterMenuButton(title: "充值", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            if isSettingsExpanded {
                Toggle(isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLoginEnabled($0) }
                )) {
                    FooterMenuButton(
                        title: "启动",
                        systemImage: "poweron",
                        isSelected: viewModel.launchAtLoginEnabled
                    )
                }
                .toggleStyle(.button)
                .buttonStyle(.plain)
                .controlSize(.small)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

                Button(role: .destructive) {
                    viewModel.logout()
                } label: {
                    FooterMenuButton(title: "清除", systemImage: "key.slash")
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .help("清除 Keychain 中保存的 API Key")
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                Button {
                    withAnimation(.snappy(duration: 0.24)) {
                        isSettingsExpanded = true
                    }
                } label: {
                    FooterMenuButton(title: "设置", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                FooterMenuButton(title: "退出", systemImage: "power")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .keyboardShortcut("q")
            .help("退出应用")
        }
        .padding(.horizontal, 8)
        .animation(.snappy(duration: 0.24), value: isSettingsExpanded)
        .onAppear {
            isSettingsExpanded = false
        }
        .onDisappear {
            isSettingsExpanded = false
        }
    }

    private func openTopUpPage() {
        guard let url = URL(string: "https://platform.deepseek.com/usage") else { return }
        NSWorkspace.shared.open(url)
    }
}

struct InlineRefreshButton: View {
    var isLoading: Bool

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 24, height: 22)
        .contentShape(Rectangle())
    }
}

struct FooterMenuButton: View {
    let title: String
    let systemImage: String
    var foregroundStyle: Color = .secondary
    var isSelected = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))

            Text(title)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundStyle(foregroundStyle)
        .padding(.horizontal, isSelected ? 7 : 0)
        .frame(height: 24)
        .background(
            Capsule()
                .fill(isSelected ? Color.accentColor.opacity(0.14) : .clear)
        )
        .contentShape(Rectangle())
    }
}

struct SubtleDivider: View {
    var body: some View {
        Divider()
            .opacity(0.38)
    }
}

struct MenuSymbolView: View {
    let systemImage: String
    var tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.16))

            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 30, height: 30)
    }
}

struct AppHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.10))

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }
}

struct StatusPillView: View {
    let isLoading: Bool
    let isAvailable: Bool
    let hasRefreshed: Bool

    var body: some View {
        HStack(spacing: 5) {
            if isLoading {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Circle()
                    .fill(statusDotColor)
                    .frame(width: 7, height: 7)
            }

            Text(statusText)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(statusForegroundStyle)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusBackgroundStyle, in: Capsule())
    }

    private var statusText: String {
        if isLoading {
            return "刷新中"
        }

        if !hasRefreshed {
            return "待刷新"
        }

        return isAvailable ? "可用" : "不可用"
    }

    private var statusForegroundStyle: Color {
        if !hasRefreshed {
            return .secondary
        }

        return isAvailable ? .green : .orange
    }

    private var statusBackgroundStyle: Color {
        if !hasRefreshed {
            return .secondary.opacity(0.12)
        }

        return isAvailable ? .green.opacity(0.15) : .orange.opacity(0.14)
    }

    private var statusDotColor: Color {
        if !hasRefreshed {
            return .secondary
        }

        return isAvailable ? .green : .orange
    }
}

struct BalanceRowView: View {
    let balanceInfo: BalanceInfo

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(balanceInfo.currency)
                    .font(.subheadline.weight(.medium))

                Text("余额账户")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Text(balanceInfo.totalBalance)
                .font(.subheadline.monospacedDigit())
        }
        .padding(10)
    }
}

struct ErrorMessageView: View {
    let message: String?

    var body: some View {
        if let message, !message.isEmpty {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct StatusMessageView: View {
    let message: String?

    var body: some View {
        if let message, !message.isEmpty {
            Label(message, systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@available(macOS 14.0, *)
struct MainViewPreviewProvider: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: AppViewModel())
    }
}
