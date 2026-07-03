<<<<<<< HEAD
import { callOpenRouterJson } from '../_shared/openrouter.ts'
=======
import { callOpenRouterVisionJson } from '../_shared/openrouter.ts'
>>>>>>> efd4786 (Auto-sync project changes)

type AnalyzeMealPayload = {
  imageBase64?: string
}

type MealAnalysis = {
  name: string
  estimatedMealType: string | null
  estimatedCalories: number | null
  estimatedProteinGrams: number | null
  estimatedCarbsGrams: number | null
  estimatedFatGrams: number | null
  estimatedSugarGrams: number | null
  estimatedFiberGrams: number | null
  confidence: number
  notes: string | null
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
    const payload = (await request.json()) as AnalyzeMealPayload
    if (!payload.imageBase64) {
      return jsonResponse({ error: 'Missing meal image.' }, 400)
    }

<<<<<<< HEAD
    const apiKey = Deno.env.get('OPENROUTER_API_KEY')
    if (!apiKey) {
=======
    if (!Deno.env.get('OPENROUTER_API_KEY')) {
>>>>>>> efd4786 (Auto-sync project changes)
      return jsonResponse(
        { error: 'OPENROUTER_API_KEY is not configured in Supabase secrets.' },
        503,
      )
    }

    const prompt = [
      'Analyze the meal photo and estimate a simple nutrition summary.',
      'Return JSON only with these fields:',
      'name, estimatedMealType, estimatedCalories, estimatedProteinGrams, estimatedCarbsGrams, estimatedFatGrams, estimatedSugarGrams, estimatedFiberGrams, confidence, notes.',
      'Confidence must be a number between 0 and 1.',
      'Keep the answer conservative and practical.',
    ].join(' ')

<<<<<<< HEAD
    const parsed = await callOpenRouterJson({
      prompt,
      imageBase64: payload.imageBase64,
=======
    const parsed = await callOpenRouterVisionJson({
      prompt,
      imageBase64: payload.imageBase64,
      maxTokens: 400,
>>>>>>> efd4786 (Auto-sync project changes)
    })

    const analysis: MealAnalysis = {
      name: String(parsed.name ?? 'Unknown meal').trim(),
      estimatedMealType: stringOrNull(parsed.estimatedMealType),
      estimatedCalories: numberOrNull(parsed.estimatedCalories),
      estimatedProteinGrams: numberOrNull(parsed.estimatedProteinGrams),
      estimatedCarbsGrams: numberOrNull(parsed.estimatedCarbsGrams),
      estimatedFatGrams: numberOrNull(parsed.estimatedFatGrams),
      estimatedSugarGrams: numberOrNull(parsed.estimatedSugarGrams),
      estimatedFiberGrams: numberOrNull(parsed.estimatedFiberGrams),
      confidence: numberOrNull(parsed.confidence) ?? 0.5,
      notes: stringOrNull(parsed.notes),
    }

    return jsonResponse({ analysis }, 200)
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      400,
    )
  }
})

function numberOrNull(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value
  }

  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value.replace(',', '.'))
    return Number.isFinite(parsed) ? parsed : null
  }

  return null
}

function stringOrNull(value: unknown): string | null {
  if (typeof value !== 'string') {
    return null
  }

  const trimmed = value.trim()
  return trimmed.length > 0 ? trimmed : null
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
