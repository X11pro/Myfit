import { callOpenRouterVisionJson } from '../_shared/openrouter.ts'

type AnalyzeMealPayload = {
  imageBase64?: string
  ingredientsText?: string
  estimatedGrams?: number
  currentName?: string
  currentCalories?: number
  currentProteinGrams?: number
  currentCarbsGrams?: number
  currentFatGrams?: number
  currentSugarGrams?: number
  currentFiberGrams?: number
}

type MealAnalysis = {
  name: string
  identifiedIngredients: string[]
  estimatedMealType: string | null
  estimatedGrams: number | null
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

    if (!Deno.env.get('OPENROUTER_API_KEY')) {
      return jsonResponse(
        { error: 'OPENROUTER_API_KEY is not configured in Supabase secrets.' },
        503,
      )
    }

    const correctedIngredients = payload.ingredientsText?.trim() ?? ''
    const correctedGrams = numberOrNull(payload.estimatedGrams)

    const prompt = [
      'Analyze the meal photo and estimate a simple nutrition summary.',
      'Return JSON only with these fields:',
      'name, identifiedIngredients, estimatedMealType, estimatedGrams, estimatedCalories, estimatedProteinGrams, estimatedCarbsGrams, estimatedFatGrams, estimatedSugarGrams, estimatedFiberGrams, confidence, notes.',
      'identifiedIngredients must be an array of short ingredient names when possible.',
      'Confidence must be a number between 0 and 1.',
      'Keep the answer conservative and practical.',
      correctedIngredients.length > 0
        ? `User-corrected ingredients (highest priority, do not ignore): ${correctedIngredients}.`
        : '',
      correctedGrams != null
        ? `User-corrected total meal weight in grams (highest priority, do not ignore): ${correctedGrams}.`
        : '',
      payload.currentName?.trim().length
        ? `Current meal name in app: ${payload.currentName!.trim()}.`
        : '',
      hasCurrentMacros(payload)
        ? `Current app macros before recalculation: calories=${numberOrNull(payload.currentCalories)}, protein=${numberOrNull(payload.currentProteinGrams)}, carbs=${numberOrNull(payload.currentCarbsGrams)}, fat=${numberOrNull(payload.currentFatGrams)}, sugar=${numberOrNull(payload.currentSugarGrams)}, fiber=${numberOrNull(payload.currentFiberGrams)}.`
        : '',
      'If the user provided corrected ingredients or weight, recompute calories and macros using those corrections instead of treating this as a first-pass photo analysis.',
      'When corrected ingredients are provided, return them back in identifiedIngredients unless there is a very strong reason to add a clearly visible missing ingredient.',
      'When corrected weight is provided, return that same weight in estimatedGrams unless the user value is impossible.',
    ].join(' ')

    const parsed = await callOpenRouterVisionJson({
      prompt,
      imageBase64: payload.imageBase64,
      maxTokens: 400,
    })

    const analysis: MealAnalysis = {
      name: String(parsed.name ?? 'Unknown meal').trim(),
      identifiedIngredients: stringArray(parsed.identifiedIngredients),
      estimatedMealType: stringOrNull(parsed.estimatedMealType),
      estimatedGrams: numberOrNull(parsed.estimatedGrams),
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

function stringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value
    .map((item) => (typeof item === 'string' ? item.trim() : ''))
    .filter((item) => item.length > 0)
}

function hasCurrentMacros(payload: AnalyzeMealPayload): boolean {
  return [
    payload.currentCalories,
    payload.currentProteinGrams,
    payload.currentCarbsGrams,
    payload.currentFatGrams,
    payload.currentSugarGrams,
    payload.currentFiberGrams,
  ].some((value) => numberOrNull(value) != null)
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
