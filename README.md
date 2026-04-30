# TokenUsage

A native macOS menu bar app that tracks Claude Code token usage and cost in real time, powered by [ccusage](https://github.com/ryoppippi/ccusage).

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License MIT](https://img.shields.io/badge/license-MIT-green)

---

## Why

`ccusage` exposes Claude Code usage locally, but running a CLI while you work breaks flow. TokenUsage puts the numbers in the menu bar so they're always one glance away — and a click opens everything: the current 5-hour billing window's countdown, per-model cost, daily / weekly / monthly breakdowns.

## Features

**At a glance (menu bar)**
- Abbreviated token count and/or cost: `◈ 1.25M` · `◈ $12.30` · `◈ 1.25M · $12.30`
- Diamond icon color reflects current 5-hour utilization — mint `< 60%` · amber `60–85%` · red `≥ 85%`
- Auto-refresh every 5 minutes; manual refresh on demand

**On click (detail panel)**
- **Hero** — cost + token total for the selected period, with input / output / cache-write / cache-read breakdown
- **7-day mini chart** — interactive bars; hover reveals per-day cost and tokens
- **5-hour block card** — live countdown to the rate-limit reset, % used, spent / projected cost; counter ticks every second
- **Weekly card** — 7-day rate-limit utilization with reset countdown (when the OAuth API is available)
- **Model breakdown** — per-model cost (Opus / Sonnet / Haiku / …)
- **Period tabs** — Today / Week / Month / All

**Settings**
- Appearance: Auto / Light / Dark (Nothing-inspired monochrome palette with mint / amber / red accents)
- Menu bar display mode: Token · Cost · Token + Cost
- Language switcher with auto-relaunch (English / 简体中文 / Español / Tiếng Việt)

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

Two data sources, refreshed every 5 minutes:

| Source | Purpose |
| --- | --- |
| `ccusage daily --json --offline` | Full daily history, filtered locally for Today / Week / Month / All |
| `ccusage blocks --json --active --offline --token-limit max` | Current 5-hour billing window (cost, projection, burn rate) |
| Anthropic OAuth usage API | Authoritative 5-hour and 7-day rate-limit utilization |

The OAuth path reads the Claude Code access token from the macOS Keychain (service `Claude Code-credentials`) and calls `https://api.anthropic.com/api/oauth/usage` — the same endpoint that powers Claude Code's official statusline. When the token is missing, expired, or `ANTHROPIC_BASE_URL` points at a non-Anthropic host, the app silently falls back to ccusage's empirical estimate so the UI keeps working offline / on custom proxies.

Results are decoded into display models and rendered via SwiftUI. The 5-hour block card uses `TimelineView` to tick every second so the reset countdown feels live without re-invoking the CLI or the API.

## Repository layout

```
TokenUsage/
├── client/                         # macOS SwiftUI app (SPM)
│   ├── TokenUsage/
│   │   ├── TokenUsageApp.swift     # MenuBarExtra entry point
│   │   ├── Models/                 # ccusage JSON + display models
│   │   ├── Services/               # CCUsageService (ccusage CLI) + AnthropicUsageService (OAuth API)
│   │   ├── ViewModels/             # UsageViewModel (MVVM, refresh scheduler)
│   │   ├── Views/
│   │   │   ├── MenuBarLabel.swift
│   │   │   ├── UsageDetailView.swift
│   │   │   └── Components/         # BlockCard, WeeklyRow, StatCard, MiniBarChart, SegmentedBar
│   │   ├── Theme/                  # Palette struct + nothingDark / nothingLight + ThemeManager
│   │   └── Utilities/              # Formatters, FontRegistration, AppLanguageManager
│   ├── Localizable.xcstrings       # String Catalog (en, zh-Hans, es, vi)
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

Strings live in `client/Localizable.xcstrings` (Apple String Catalog). Currently shipping `en` (source), `zh-Hans`, `es`, and `vi`. To add a locale:

1. Open `Localizable.xcstrings` in Xcode and add the new language.
2. Add the code to `AppLanguage` in `Utilities/AppLanguageManager.swift`.
3. Add the code to `CFBundleLocalizations` in `client/build.sh`.

## License

MIT
