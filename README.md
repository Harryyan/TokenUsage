# TokenUsage

A native macOS menu bar app that tracks Claude Code token usage and cost in real time, powered by [ccusage](https://github.com/ryoppippi/ccusage).

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License MIT](https://img.shields.io/badge/license-MIT-green)

---

## Why

`ccusage` exposes Claude Code usage locally, but running a CLI while you work breaks flow. TokenUsage puts the numbers in the menu bar so they're always one glance away — and a click opens everything: the current 5-hour billing window's countdown, per-model cost, daily / weekly / monthly breakdowns.

## Features

**At a glance (menu bar)**
- Abbreviated token count and/or cost: `◈ 1.25M` · `◈ $12.30` · `◈ 1.25M · $12.30`
- Auto-refresh every 5 minutes; manual refresh on demand

**On click (detail panel)**
- **5-hour block card** — countdown to the next rate-limit reset with spent / projected cost; counter ticks live every second
- **Hero card** — cost + token total for the selected period, with input / output / cache-write / cache-read breakdown
- **Model breakdown** — per-model cost (Opus / Sonnet / Haiku / …)
- **Daily averages** — for Week / Month / All-time
- **Period tabs** — Today / Week / Month / All

**Settings**
- 5 built-in pixel-RPG color themes (Pixel Gold, Terminal Green, Synthwave, Gruvbox, Game Boy)
- Menu bar display mode switcher (Token · Cost · Token + Cost)
- In-app language switcher with auto-relaunch (English / 简体中文)

## Requirements

- macOS 13.0+
- [Node.js](https://nodejs.org/) (for `npx`)
- [ccusage](https://github.com/ryoppippi/ccusage) available via `npx` or installed globally

## Build & Run

```bash
cd client
./build.sh
open TokenUsage.app
```

To install system-wide:

```bash
cp -R TokenUsage.app /Applications/
```

## How it works

The client shells out to `npx ccusage` on a 5-minute cadence:

| Command | Purpose |
| --- | --- |
| `ccusage daily --json --offline` | Full daily history, filtered locally for Today / Week / Month / All |
| `ccusage blocks --json --active --offline` | Current 5-hour billing window (drives the block card) |

Results are decoded into display models and rendered via SwiftUI. The 5-hour block card uses `TimelineView` to tick every second so the reset countdown feels live without re-invoking the CLI.

## Repository layout

```
TokenUsage/
├── client/                         # macOS SwiftUI app (SPM)
│   ├── TokenUsage/
│   │   ├── TokenUsageApp.swift     # MenuBarExtra entry point
│   │   ├── Models/                 # ccusage JSON + display models
│   │   ├── Services/               # CCUsageService (Process → ccusage)
│   │   ├── ViewModels/             # UsageViewModel (MVVM, refresh scheduler)
│   │   ├── Views/
│   │   │   ├── MenuBarLabel.swift
│   │   │   ├── UsageDetailView.swift
│   │   │   └── Components/         # BlockCard, StatCard, pixel primitives
│   │   ├── Theme/                  # Theme struct + 5 palettes + ThemeManager
│   │   └── Utilities/              # Formatters, AppLanguageManager
│   ├── Localizable.xcstrings       # String Catalog (en, zh-Hans)
│   ├── Package.swift
│   └── build.sh
├── server/                         # Supabase multi-device sync backend (WIP)
│   └── supabase/
│       ├── migrations/
│       └── functions/              # sync-usage · usage edge functions
├── PRDS/                           # Product requirement docs
└── README.md
```

## Server (work in progress)

`server/` holds a Supabase-backed multi-device sync backend — Postgres schema, RLS policies, and two Edge Functions (`sync-usage`, `usage`) — specified in `PRDS/PRD-1.md`. The backend is implemented; the macOS client does **not** yet call it, so today the app is local-only. See `server/README.md` for deployment.

## Localization

Strings live in `client/Localizable.xcstrings` (Apple String Catalog). Currently shipping `en` (source) and `zh-Hans`. To add a locale:

1. Open `Localizable.xcstrings` in Xcode and add the new language.
2. Add the code to `AppLanguage` in `Utilities/AppLanguageManager.swift`.
3. Add the code to `CFBundleLocalizations` in `client/build.sh`.

## License

MIT
