import SwiftUI

@available(macOS 14.0, *)
@main
struct DeepSeekBalanceBarApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            if #available(macOS 14.0, *) {
                MainView(viewModel: viewModel)
            } else {
                // Fallback on earlier versions
            }
        } label: {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .offset(y: 1)
                .accessibilityLabel("DeepSeek Balance")
        }
        .menuBarExtraStyle(.window)
    }
}
