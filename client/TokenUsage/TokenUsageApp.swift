import SwiftUI

@main
struct TokenUsageApp: App {
    @StateObject private var viewModel = UsageViewModel()
    @StateObject private var themeManager = ThemeManager()

    init() {
        AppLanguageManager.applyPreferredLanguageIfNeeded()
        FontRegistration.registerBundledFonts()
    }

    var body: some Scene {
        MenuBarExtra {
            UsageDetailView(viewModel: viewModel)
                .environmentObject(themeManager)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
