import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const STATUS_THRESHOLDS = {
  ONLINE_MS: 10 * 60 * 1000,
  STALE_MS: 60 * 60 * 1000,
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders() });
  }

  if (req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing authorization" }, 401);
  }

  const jwt = authHeader.slice(7);
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(jwt);

  if (authError || !user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const accountId = user.id;
  const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    db: { schema: "public" },
  });

  // Fetch rollup
  const { data: rollup, error: rollupError } = await db
    .from("account_rollups")
    .select("*")
    .eq("account_id", accountId)
    .maybeSingle();

  if (rollupError) {
    return jsonResponse({ error: "Failed to fetch rollup", detail: rollupError.message }, 500);
  }

  // Fetch devices with their summaries
  const { data: devices, error: devicesError } = await db
    .from("devices")
    .select(`
      id,
      device_name,
      machine_id,
      os_version,
      app_version,
      last_seen_at,
      created_at,
      device_summaries (
        synced_at,
        today_tokens,
        today_cost,
        week_tokens,
        week_cost,
        month_tokens,
        month_cost,
        total_tokens,
        total_cost,
        schema_version
      )
    `)
    .eq("account_id", accountId)
    .order("last_seen_at", { ascending: false });

  if (devicesError) {
    return jsonResponse({ error: "Failed to fetch devices", detail: devicesError.message }, 500);
  }

  const now = Date.now();

  const devicesWithStatus = (devices ?? []).map((d) => {
    const lastSeen = new Date(d.last_seen_at).getTime();
    const elapsed = now - lastSeen;

    let status: string;
    if (elapsed < STATUS_THRESHOLDS.ONLINE_MS) {
      status = "online";
    } else if (elapsed < STATUS_THRESHOLDS.STALE_MS) {
      status = "stale";
    } else {
      status = "offline";
    }

    const summary = Array.isArray(d.device_summaries)
      ? d.device_summaries[0] ?? null
      : d.device_summaries;

    return {
      id: d.id,
      name: d.device_name,
      machine_id: d.machine_id,
      os_version: d.os_version,
      app_version: d.app_version,
      status,
      last_seen_at: d.last_seen_at,
      created_at: d.created_at,
      summary,
    };
  });

  const rollupResponse = rollup
    ? {
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
        aggregated_at: rollup.aggregated_at,
      }
    : null;

  return jsonResponse({
    rollup: rollupResponse,
    devices: devicesWithStatus,
  });
});

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
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
