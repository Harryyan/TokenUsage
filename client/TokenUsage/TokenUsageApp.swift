import SwiftUI

@main
struct TokenUsageApp: App {
    @StateObject private var viewModel = UsageViewModel()

    init() {
        AppLanguageManager.applyPreferredLanguageIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            UsageDetailView(viewModel: viewModel)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
