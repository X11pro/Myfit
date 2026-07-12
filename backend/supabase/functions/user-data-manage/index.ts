import { createClient } from 'npm:@supabase/supabase-js@2'

type ManagePayload = {
  action?: 'export' | 'delete'
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const authHeader = request.headers.get('Authorization')

    if (!supabaseUrl || !anonKey || !serviceRoleKey || !authHeader) {
      throw new Error('Missing Supabase configuration or auth header.')
    }

    const payload = (await request.json()) as ManagePayload
    const action = payload.action ?? 'export'

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const serviceClient = createClient(supabaseUrl, serviceRoleKey)

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()

    if (userError || !user) {
      throw new Error('User session is not valid anymore.')
    }

    if (action === 'delete') {
      await deleteUserData(serviceClient, user.id)
      return jsonResponse({ success: true }, 200)
    }

    const exportPayload = await exportUserData(serviceClient, user.id)
    return jsonResponse({ data: exportPayload }, 200)
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      400,
    )
  }
})

async function exportUserData(supabase: ReturnType<typeof createClient>, userId: string) {
  const [profile, bodyMetrics, mealPhotos, mealEntries, workoutSessions, gymSets] = await Promise.all([
    selectTable(supabase, 'profiles', userId),
    selectTable(supabase, 'body_metrics', userId),
    selectTable(supabase, 'meal_photos', userId),
    selectTable(supabase, 'meal_entries', userId),
    selectTable(supabase, 'workout_sessions', userId),
    selectGymSets(supabase, userId),
  ])

  return {
    exportedAt: new Date().toISOString(),
    userId,
    profile,
    bodyMetrics,
    mealPhotos,
    mealEntries,
    workoutSessions,
    gymSets,
  }
}

async function deleteUserData(supabase: ReturnType<typeof createClient>, userId: string) {
  const { data: photos, error: photoListError } = await supabase
    .from('meal_photos')
    .select('id, storage_path')
    .eq('user_id', userId)

  if (photoListError) {
    throw photoListError
  }

  const storagePaths = (photos ?? [])
    .map((item) => item.storage_path as string | null)
    .filter((value): value is string => !!value && value.trim().length > 0)

  if (storagePaths.length > 0) {
    const { error: storageError } = await supabase.storage
      .from('meal-photos')
      .remove(storagePaths)
    if (storageError) {
      throw storageError
    }
  }

  await deleteTable(supabase, 'body_metrics', userId)
  await deleteTable(supabase, 'meal_entries', userId)
  await deleteTable(supabase, 'meal_photos', userId)
  await deleteTable(supabase, 'workout_sessions', userId)
  await deleteTable(supabase, 'profiles', userId)
}

async function selectTable(
  supabase: ReturnType<typeof createClient>,
  table: string,
  userId: string,
) {
  const { data, error } = await supabase.from(table).select('*').eq('user_id', userId)
  if (error) {
    throw error
  }
  return data ?? []
}

async function selectGymSets(supabase: ReturnType<typeof createClient>, userId: string) {
  const { data, error } = await supabase
    .from('gym_sets')
    .select('*, workout_sessions!inner(user_id)')
    .eq('workout_sessions.user_id', userId)

  if (error) {
    throw error
  }

  return (data ?? []).map(({ workout_sessions, ...rest }) => rest)
}

async function deleteTable(
  supabase: ReturnType<typeof createClient>,
  table: string,
  userId: string,
) {
  const { error } = await supabase.from(table).delete().eq('user_id', userId)
  if (error) {
    throw error
  }
}

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}
