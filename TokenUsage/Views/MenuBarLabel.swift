import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 4) {
            if viewModel.refreshState.isLoading {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            Text(viewModel.menuBarText)
                .monospacedDigit()
        }
    }
}
