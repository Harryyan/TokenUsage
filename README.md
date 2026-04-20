# TokenUsage

A native macOS Menu Bar app that displays real-time Claude Code token usage and costs, powered by [ccusage](https://github.com/ryoppippi/ccusage).

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Menu Bar Display** — Live token usage in compact abbreviated format (e.g. 1.25M, 23.5K)
- **Detail Panel** — Click to view full breakdown by Today / This Week / This Month / Total
- **Token Breakdown** — Input, Output, Cache Write, Cache Read with precise numbers
- **Model Breakdown** — Per-model cost and token usage
- **Cost Tracking** — Real-time cost calculation in USD
- **Auto Refresh** — Updates every 5 minutes, with manual refresh support
- **Display Modes** — Switch between Token Only, Token + Cost, or Cost Only in menu bar
- **Native macOS** — Built with SwiftUI, supports Light/Dark mode

## Screenshots

| Menu Bar | Detail Panel |
|----------|-------------|
| `◈ 80.6K` | Token breakdown, model costs, daily averages |

## Prerequisites

- macOS 13.0+
- [Node.js](https://nodejs.org/) (for npx)
- [ccusage](https://github.com/ryoppippi/ccusage) — installed globally or available via npx

## Build

```bash
# Build the .app bundle
./build.sh

# Run
open TokenUsage.app

# Install to Applications
cp -R TokenUsage.app /Applications/
```

## Architecture

```
TokenUsage/
├── TokenUsageApp.swift          # App entry point (MenuBarExtra)
├── Models/
│   └── UsageModels.swift        # Data models (ccusage JSON + display models)
├── Services/
│   └── CCUsageService.swift     # Async ccusage CLI integration
├── ViewModels/
│   └── UsageViewModel.swift     # MVVM ViewModel, data aggregation, refresh scheduler
├── Views/
│   ├── MenuBarLabel.swift       # Dynamic menu bar label
│   ├── UsageDetailView.swift    # Popover detail panel
│   └── Components/
│       └── StatCard.swift       # Reusable stat card & token breakdown row
└── Utilities/
    └── Formatters.swift         # Token (K/M/B) and cost ($) formatters
```

## How It Works

1. Calls `npx ccusage daily --json --offline` once per refresh cycle
2. Filters the full daily dataset locally for Today / Week / Month / Total
3. Aggregates token counts and costs per period
4. Displays abbreviated values in menu bar, precise values in the detail panel

## License

MIT
