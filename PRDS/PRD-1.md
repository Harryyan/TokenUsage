---
title: Claude Code Multi-Device Usage Sync Backend MVP
version: v2.0
status: Draft
owner: Harry Yan
scope: Server-side only
last_updated: 2026-04-21
---

# PRD: Multi-Device Usage Sync Backend MVP

---

## 1. Background

### 1.1 Current State
已有一个 macOS Menu Bar App（PRD-0），通过 `ccusage` CLI 读取本地 Claude Code 使用数据，展示 token 用量和费用。

### 1.2 Problem
用户在多台 Mac 上使用 Claude Code，但每台机器只能看到本机数据。需要一个轻量后端，把多台设备的用量汇总到账户级别。

### 1.3 Data Source Semantics
**关键事实：** `ccusage` 读取的是本地 `~/.claude/` 目录下的 session JSONL 日志。每台机器的 session 数据完全独立——Mac A 上的对话不会出现在 Mac B 的日志中。因此，跨设备直接求和是精确的，不存在重复计数问题。

---

## 2. Goals

### 2.1 MVP Must
1. 一个账户关联多台设备
2. 每台设备定期上传用量摘要
3. 后端存储每台设备的最新摘要
4. 后端计算并存储账户级汇总
5. 提供 API 供客户端读取汇总数据

### 2.2 Success Criteria
- 3 台设备各自上传数据后，客户端能读到正确的账户级 token/cost 汇总
- 端到端延迟 < 5 秒（从上传到汇总可读）

### 2.3 Non-Goals
- 客户端改动（Swift/SwiftUI）
- Web dashboard / Admin console
- 多用户 / 多组织 / RBAC
- 原始事件级数据采集
- Session 级去重（不需要，见 1.3）
- 历史趋势分析

---

## 3. Tech Stack Decision

### 3.1 Recommendation: Supabase

| Criteria | Firebase | Supabase | Node+PG | CF Workers+D1 |
|----------|----------|----------|---------|----------------|
| 免费额度 | 好 | 好 | 需自建 | 好 |
| 内置 Auth | Yes | Yes | No | No |
| 数据库 | NoSQL | Postgres | Postgres | SQLite |
| Edge Functions | Yes | Yes | 需部署 | Yes |
| 类型安全 | 弱 | 强(PG+TS) | 强 | 强 |
| 运维成本 | 零 | 零 | 高 | 低 |
| 数据可移植性 | 低 | 高(标准PG) | 高 | 低 |
| MVP 交付速度 | 快 | 快 | 慢 | 中 |

**选择 Supabase 的理由：**
- 免费 tier 完全够用（单用户 + 3 设备）
- 内置 Auth 开箱即用，无需自建认证
- Postgres 是标准关系数据库，数据模型清晰，未来可移植
- Edge Functions (Deno) 处理业务逻辑
- Row Level Security (RLS) 天然支持数据隔离
- Dashboard 自带数据管理，无需 admin 工具

**不选其他的理由：**
- Firebase: Firestore 的 NoSQL 模型对聚合查询不友好，数据可移植性差
- Node+PG: 需要自己搞部署、运维、Auth，对个人项目来说成本太高
- CF Workers+D1: D1 是 SQLite，功能有限；没有内置 Auth

### 3.2 Architecture Overview

```
macOS Client (each device)
    │
    │  POST /functions/v1/sync-usage
    │  (Bearer token from Supabase Auth)
    │
    ▼
Supabase Edge Function ──── sync-usage
    │
    │  1. Validate + extract user
    │  2. Upsert device
    │  3. Upsert device_summary
    │  4. Recompute account_rollup
    │
    ▼
Supabase Postgres (with RLS)
    ├── accounts
    ├── devices
    ├── device_summaries
    └── account_rollups
```

### 3.3 Write Path Decision

**选择 Option B — Edge Function 控制写入。**

理由：
- 客户端直写 + DB triggers 看似简单，但 trigger 里做聚合容易出错且难调试
- Edge Function 提供一个清晰的事务边界：验证 → 写入 → 聚合，全在一个请求里完成
- 安全校验在应用层做，不依赖 RLS 规则的复杂组合
- 成本：Supabase 免费 tier 包含 500K Edge Function 调用/月，绰绰有余

---

## 4. Data Model

### 4.1 accounts

| Field | Type | Note |
|-------|------|------|
| id | uuid PK | = auth.users.id |
| email | text | from auth |
| display_name | text | nullable |
| timezone | text | default 'Pacific/Auckland' |
| created_at | timestamptz | |
| updated_at | timestamptz | |

直接复用 Supabase Auth 的 user id 作为 account id，不需要额外的映射层。

### 4.2 devices

| Field | Type | Note |
|-------|------|------|
| id | uuid PK | 客户端生成，持久化在本地 |
| account_id | uuid FK → accounts.id | |
| device_name | text | 用户可读名称，如 "Harry's MacBook Pro" |
| machine_id | text | 硬件标识，用于去重 |
| os_version | text | |
| app_version | text | |
| last_seen_at | timestamptz | 最后一次上传时间 |
| created_at | timestamptz | |

**设备状态不持久化，读取时按 `last_seen_at` 动态计算：**
- < 10 min → online
- 10 min ~ 1 hour → stale
- > 1 hour → offline

### 4.3 device_summaries

| Field | Type | Note |
|-------|------|------|
| device_id | uuid PK, FK → devices.id | 一设备一行，upsert |
| account_id | uuid FK → accounts.id | 冗余，加速聚合查询 |
| synced_at | timestamptz | 客户端采集时间 |
| today_tokens | bigint | |
| today_cost | numeric(12,4) | |
| week_tokens | bigint | |
| week_cost | numeric(12,4) | |
| month_tokens | bigint | |
| month_cost | numeric(12,4) | |
| total_tokens | bigint | |
| total_cost | numeric(12,4) | |
| schema_version | int | 数据格式版本，便于未来兼容 |
| updated_at | timestamptz | |

**关于精度：** `numeric(12,4)` 支持最大 99,999,999.9999，足够覆盖个人使用场景。

### 4.4 account_rollups

| Field | Type | Note |
|-------|------|------|
| account_id | uuid PK, FK → accounts.id | 一账户一行 |
| today_tokens | bigint | SUM of devices |
| today_cost | numeric(12,4) | |
| week_tokens | bigint | |
| week_cost | numeric(12,4) | |
| month_tokens | bigint | |
| month_cost | numeric(12,4) | |
| total_tokens | bigint | |
| total_cost | numeric(12,4) | |
| device_count | int | 总设备数 |
| freshest_sync_at | timestamptz | MAX of device synced_at |
| aggregated_at | timestamptz | 聚合计算时间 |

### 4.5 Data Relationship

```
accounts (1) ──── (N) devices
    │                    │
    │                    │ (1:1)
    │                    ▼
    │              device_summaries
    │
    │ (1:1)
    ▼
account_rollups
```

### 4.6 What Was Removed vs PRD v1

以下字段在 v1 中存在但被移除，原因是 MVP 不需要：

| Removed | Reason |
|---------|--------|
| preferredCurrency | 单用户，硬编码 USD |
| rawPayloadHash | 没有去重需求（见 1.3） |
| errorState / uploadStatus | 上传成功就有数据，失败客户端重试即可 |
| currentDisplayTokens/Cost | 这是客户端展示逻辑，不属于后端 |
| sourceVersion | app_version 已覆盖 |
| dataSchemaVersion on rollup | rollup 由后端自己算，不需要版本标记 |
| device.status | 改为动态计算，不持久化 |
| device.platform | 当前只有 macOS，无意义 |
| activeDeviceCount/onlineDeviceCount/staleDeviceCount/offlineDeviceCount | 客户端根据 last_seen_at 自行计算 |
| Snapshot History | MVP 不需要历史，设备摘要已经是"最新一条" |

---

## 5. API Design

### 5.1 POST /functions/v1/sync-usage

客户端每 5 分钟调用一次，上传最新用量摘要。

**Request:**
```json
{
  "device": {
    "id": "uuid",
    "name": "Harry's MacBook Pro",
    "machine_id": "hardware-uuid",
    "os_version": "macOS 15.4",
    "app_version": "1.2.0"
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
    "total_cost": 1112.50,
    "schema_version": 1
  }
}
```

**Response (200):**
```json
{
  "status": "ok",
  "rollup": {
    "today_tokens": 2100000,
    "today_cost": 26.25,
    "week_tokens": 9200000,
    "week_cost": 115.00,
    "month_tokens": 41000000,
    "month_cost": 512.50,
    "total_tokens": 156000000,
    "total_cost": 1950.00,
    "device_count": 3,
    "freshest_sync_at": "2026-04-21T10:30:00Z",
    "aggregated_at": "2026-04-21T10:30:01Z"
  }
}
```

**设计决策：** 上传成功后直接返回最新 rollup。这样客户端一次请求就能拿到账户级汇总，不需要额外的 GET 请求。对于 5 分钟一次的频率，这个策略简单且高效。

### 5.2 GET /functions/v1/usage

客户端主动拉取最新汇总（可选，用于首次启动或手动刷新）。

**Response (200):**
```json
{
  "rollup": { ... },
  "devices": [
    {
      "id": "uuid",
      "name": "Harry's MacBook Pro",
      "status": "online",
      "last_seen_at": "2026-04-21T10:30:00Z",
      "summary": {
        "today_tokens": 1250000,
        "today_cost": 15.60,
        ...
      }
    },
    ...
  ]
}
```

### 5.3 Authentication

使用 Supabase Auth，客户端通过 email/password 登录获取 JWT。

所有 API 请求携带 `Authorization: Bearer <jwt>`。Edge Function 中通过 `supabase.auth.getUser()` 验证身份并提取 `user.id` 作为 `account_id`。

**MVP 阶段不需要：**
- API Key 机制
- OAuth / SSO
- Device-level token

JWT 已经绑定了用户身份，加上 RLS 规则，足以确保数据隔离。

---

## 6. Aggregation Strategy

### 6.1 Trigger: Recompute on Each Write

每次 sync-usage 调用时，在同一个 Edge Function 里：
1. Upsert device + device_summary
2. `SELECT SUM(...), MAX(...), COUNT(*) FROM device_summaries WHERE account_id = $1`
3. Upsert account_rollups

**为什么不用其他方案：**
- Scheduled recompute: 引入延迟，MVP 没必要
- Compute on read: 每次读都要聚合，3 设备虽然不贵，但不如预计算干净
- DB trigger: 调试困难，Edge Function 里显式写更可控

### 6.2 Why Direct Summation Is Correct

`ccusage` 读取 `~/.claude/projects/` 下的本地 JSONL session 日志。这些日志是 Claude Code 在本机创建的对话记录，不会跨设备同步。因此：

- Mac A 报告的 today_tokens 是 Mac A 上今天的实际使用量
- Mac B 报告的 today_tokens 是 Mac B 上今天的实际使用量
- SUM(today_tokens) = 用户今天在所有设备上的总使用量

**这不是近似，是精确的。** 不存在 v1 PRD 中担心的"重复计数风险"。

唯一的边缘情况：如果用户把 `~/.claude/` 目录通过 iCloud/Dropbox 同步到多台机器，同一份日志可能被多台设备重复上报。但这是用户自己的配置错误，不在正常使用场景内。可以在文档中注明。

---

## 7. Row Level Security (RLS)

```sql
-- accounts: 用户只能读写自己的账户
CREATE POLICY "users_own_account" ON accounts
  FOR ALL USING (id = auth.uid());

-- devices: 用户只能读写自己的设备
CREATE POLICY "users_own_devices" ON devices
  FOR ALL USING (account_id = auth.uid());

-- device_summaries: 用户只能读写自己的设备摘要
CREATE POLICY "users_own_summaries" ON device_summaries
  FOR ALL USING (account_id = auth.uid());

-- account_rollups: 用户只能读自己的汇总
CREATE POLICY "users_own_rollups" ON account_rollups
  FOR ALL USING (account_id = auth.uid());
```

Edge Function 使用 service role key 绕过 RLS 执行写入（因为需要在一个事务里完成 upsert + 聚合）。GET 请求可以直接走 RLS。

---

## 8. Edge Function Logic (Pseudocode)

```typescript
// sync-usage
async function handler(req: Request) {
  const supabase = createClient(url, serviceRoleKey)
  const { data: { user } } = await supabase.auth.getUser(jwt)

  const { device, summary } = await req.json()
  const accountId = user.id

  // 1. Ensure account exists
  await supabase.from('accounts').upsert({
    id: accountId,
    email: user.email,
    updated_at: new Date()
  })

  // 2. Upsert device
  await supabase.from('devices').upsert({
    id: device.id,
    account_id: accountId,
    device_name: device.name,
    machine_id: device.machine_id,
    os_version: device.os_version,
    app_version: device.app_version,
    last_seen_at: new Date()
  })

  // 3. Upsert device summary
  await supabase.from('device_summaries').upsert({
    device_id: device.id,
    account_id: accountId,
    ...summary,
    updated_at: new Date()
  })

  // 4. Recompute rollup
  const { data: agg } = await supabase.rpc('compute_account_rollup', {
    p_account_id: accountId
  })

  // 5. Upsert rollup
  await supabase.from('account_rollups').upsert({
    account_id: accountId,
    ...agg,
    aggregated_at: new Date()
  })

  return Response.json({ status: 'ok', rollup: agg })
}
```

```sql
-- Postgres function for aggregation
CREATE FUNCTION compute_account_rollup(p_account_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'today_tokens', COALESCE(SUM(today_tokens), 0),
    'today_cost', COALESCE(SUM(today_cost), 0),
    'week_tokens', COALESCE(SUM(week_tokens), 0),
    'week_cost', COALESCE(SUM(week_cost), 0),
    'month_tokens', COALESCE(SUM(month_tokens), 0),
    'month_cost', COALESCE(SUM(month_cost), 0),
    'total_tokens', COALESCE(SUM(total_tokens), 0),
    'total_cost', COALESCE(SUM(total_cost), 0),
    'device_count', COUNT(*),
    'freshest_sync_at', MAX(synced_at)
  )
  FROM device_summaries
  WHERE account_id = p_account_id
$$ LANGUAGE sql STABLE;
```

---

## 9. Project Structure

```
backend/
├── supabase/
│   ├── config.toml                  # Supabase project config
│   ├── migrations/
│   │   └── 001_initial_schema.sql   # Tables, RLS, functions
│   └── functions/
│       ├── sync-usage/
│       │   └── index.ts             # Device upload + rollup
│       └── usage/
│           └── index.ts             # Read rollup + devices
├── .env.example                     # Required env vars
└── README.md                        # Setup + deploy instructions
```

---

## 10. Delivery Plan

### Phase 1 — MVP (This PRD)
- [ ] Supabase project setup
- [ ] DB schema migration (tables + RLS + functions)
- [ ] sync-usage Edge Function
- [ ] usage Edge Function
- [ ] Auth flow (email/password)
- [ ] README with setup instructions
- [ ] Manual testing with curl / Postman

### Phase 2 — Hardening
- Idempotency: 根据 synced_at 判断是否跳过重复上传
- Input validation: 对 summary 字段做范围检查
- Device status thresholds 可配置化
- Error logging / monitoring

### Phase 3 — Future
- Historical snapshots (每日快照，支持趋势图)
- Budget alerts
- 多用户支持
- Web dashboard

---

## 11. Assumptions

1. 单用户场景，初始 ~3 台设备
2. `ccusage` 数据完全本地，无跨设备重复
3. 上传频率 ~5 分钟/设备，写入量极低
4. Supabase 免费 tier 完全覆盖需求
5. 客户端改动（Swift 侧对接）不在此 PRD 范围内
