import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface SyncRequest {
  device: {
    id: string;
    name: string;
    machine_id: string;
    os_version?: string;
    app_version?: string;
  };
  summary: {
    synced_at: string;
    today_tokens: number;
    today_cost: number;
    week_tokens: number;
    week_cost: number;
    month_tokens: number;
    month_cost: number;
    total_tokens: number;
    total_cost: number;
    schema_version?: number;
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders(),
    });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // Authenticate user via JWT
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing authorization" }, 401);
  }

  const jwt = authHeader.slice(7);
  const supabaseAuth = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const {
    data: { user },
    error: authError,
  } = await supabaseAuth.auth.getUser(jwt);

  if (authError || !user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const accountId = user.id;

  // Parse request body
  let body: SyncRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  if (!body.device?.id || !body.device?.name || !body.device?.machine_id) {
    return jsonResponse({ error: "Missing required device fields" }, 400);
  }
  if (!body.summary?.synced_at) {
    return jsonResponse({ error: "Missing required summary fields" }, 400);
  }

  const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    db: { schema: "public" },
  });

  // 1. Ensure account exists
  const { error: accountError } = await db.from("accounts").upsert(
    {
      id: accountId,
      email: user.email ?? "",
      updated_at: new Date().toISOString(),
    },
    { onConflict: "id" }
  );

  if (accountError) {
    return jsonResponse({ error: "Failed to upsert account", detail: accountError.message }, 500);
  }

  // 2. Upsert device
  const { error: deviceError } = await db.from("devices").upsert(
    {
      id: body.device.id,
      account_id: accountId,
      device_name: body.device.name,
      machine_id: body.device.machine_id,
      os_version: body.device.os_version ?? null,
      app_version: body.device.app_version ?? null,
      last_seen_at: new Date().toISOString(),
    },
    { onConflict: "id" }
  );

  if (deviceError) {
    return jsonResponse({ error: "Failed to upsert device", detail: deviceError.message }, 500);
  }

  // 3. Upsert device summary
  const { error: summaryError } = await db.from("device_summaries").upsert(
    {
      device_id: body.device.id,
      account_id: accountId,
      synced_at: body.summary.synced_at,
      today_tokens: body.summary.today_tokens,
      today_cost: body.summary.today_cost,
      week_tokens: body.summary.week_tokens,
      week_cost: body.summary.week_cost,
      month_tokens: body.summary.month_tokens,
      month_cost: body.summary.month_cost,
      total_tokens: body.summary.total_tokens,
      total_cost: body.summary.total_cost,
      schema_version: body.summary.schema_version ?? 1,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "device_id" }
  );

  if (summaryError) {
    return jsonResponse({ error: "Failed to upsert summary", detail: summaryError.message }, 500);
  }

  // 4. Recompute account rollup
  const { data: rollupData, error: rollupComputeError } = await db.rpc(
    "compute_account_rollup",
    { p_account_id: accountId }
  );

  if (rollupComputeError) {
    return jsonResponse({ error: "Failed to compute rollup", detail: rollupComputeError.message }, 500);
  }

  const rollup = rollupData as Record<string, unknown>;
  const now = new Date().toISOString();

  const { error: rollupUpsertError } = await db.from("account_rollups").upsert(
    {
      account_id: accountId,
      today_tokens: rollup.today_tokens,
      today_cost: rollup.today_cost,
      week_tokens: rollup.week_tokens,
      week_cost: rollup.week_cost,
      month_tokens: rollup.month_tokens,
      month_cost: rollup.month_cost,
      total_tokens: rollup.total_tokens,
      total_cost: rollup.total_cost,
      device_count: rollup.device_count,
      freshest_sync_at: rollup.freshest_sync_at,
      aggregated_at: now,
    },
    { onConflict: "account_id" }
  );

  if (rollupUpsertError) {
    return jsonResponse({ error: "Failed to upsert rollup", detail: rollupUpsertError.message }, 500);
  }

  return jsonResponse({
    status: "ok",
    rollup: {
      ...rollup,
      aggregated_at: now,
    },
  });
});

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
  };
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}
