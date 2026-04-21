# TokenUsage Sync Backend

Multi-device Claude Code usage sync backend, powered by Supabase.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) (`brew install supabase/tap/supabase`)
- A Supabase project (create at https://supabase.com/dashboard)
- Deno (bundled with Supabase CLI)

## Setup

### 1. Link to your Supabase project

```bash
cd server
supabase link --project-ref <your-project-ref>
```

### 2. Run database migration

```bash
supabase db push
```

This creates the tables (`accounts`, `devices`, `device_summaries`, `account_rollups`), RLS policies, and the `compute_account_rollup` function.

### 3. Deploy Edge Functions

```bash
supabase functions deploy sync-usage
supabase functions deploy usage
```

### 4. Create a user

Go to Supabase Dashboard > Authentication > Users > Add User, or use the API:

```bash
curl -X POST "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "hy@mega.co.nz", "password": "your-password"}'
```

## API

### POST /functions/v1/sync-usage

Upload device usage summary. Called by the macOS client every 5 minutes.

```bash
# First, get a JWT token
TOKEN=$(curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "hy@mega.co.nz", "password": "your-password"}' \
  | jq -r '.access_token')

# Sync usage
curl -X POST "$SUPABASE_URL/functions/v1/sync-usage" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "MacBook Pro Office",
      "machine_id": "C02X1234ABCD",
      "os_version": "macOS 15.4",
      "app_version": "1.0.0"
    },
    "summary": {
      "synced_at": "2026-04-21T10:30:00Z",
      "today_tokens": 1250000,
      "today_cost": 15.60,
      "week_tokens": 5800000,
      "week_cost": 72.50,
      "month_tokens": 23500000,
      "month_cost": 293.75,
      "total_tokens": 89000000,
      "total_cost": 1112.50
    }
  }'
```

Response:
```json
{
  "status": "ok",
  "rollup": {
    "today_tokens": 2100000,
    "today_cost": 26.25,
    "device_count": 3,
    "freshest_sync_at": "2026-04-21T10:30:00Z",
    "aggregated_at": "2026-04-21T10:30:01Z",
    "..."
  }
}
```

### GET /functions/v1/usage

Fetch account rollup and all device details.

```bash
curl "$SUPABASE_URL/functions/v1/usage" \
  -H "Authorization: Bearer $TOKEN"
```

Response:
```json
{
  "rollup": { "today_tokens": 2100000, "..." },
  "devices": [
    {
      "id": "...",
      "name": "MacBook Pro Office",
      "status": "online",
      "last_seen_at": "...",
      "summary": { "today_tokens": 1250000, "..." }
    }
  ]
}
```

## Local Development

```bash
supabase start          # Start local Supabase stack (Docker required)
supabase functions serve # Serve Edge Functions locally
```

## Architecture

```
macOS Client ──POST──▶ sync-usage Edge Function
                            │
                            ├─ upsert account
                            ├─ upsert device
                            ├─ upsert device_summary
                            ├─ compute_account_rollup()
                            └─ upsert account_rollup
                                    │
                            ◀───────┘ return rollup

macOS Client ──GET───▶ usage Edge Function
                            │
                            ├─ read account_rollup
                            ├─ read devices + summaries
                            └─ compute device status
                                    │
                            ◀───────┘ return rollup + devices
```
