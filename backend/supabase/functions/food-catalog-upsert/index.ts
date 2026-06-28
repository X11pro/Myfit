import { createClient } from 'npm:@supabase/supabase-js@2'
import { callOpenRouterVisionJson } from '../_shared/openrouter.ts'

type Mode = 'extract' | 'upsert'

type CatalogPayload = {
  mode?: Mode
  barcode?: string
  source?: string
  imageBase64?: string
  ocrText?: string
  name?: string
  brand?: string
  caloriesPer100g?: number
  proteinPer100g?: number
  carbsPer100g?: number
  fatPer100g?: number
  sugarPer100g?: number
  fiberPer100g?: number
}

type NormalizedFood = {
  source: string
  sourceId: string | null
  name: string
  brand: string | null
  caloriesPer100g: number | null
  proteinPer100g: number | null
  carbsPer100g: number | null
  fatPer100g: number | null
  sugarPer100g: number | null
  fiberPer100g: number | null
  confidence: number
  nutritionQualityScore: number | null
  nutritionQualityReason: string | null
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
    const payload = (await request.json()) as CatalogPayload
    const mode = payload.mode ?? 'upsert'
    const food = await normalizeFood(payload)

    if (mode === 'extract') {
      return jsonResponse({ food }, 200)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('Missing Supabase service role configuration.')
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey)
    const { data, error } = await supabase
      .from('food_items')
      .upsert(
        {
          source: food.source,
          source_id: food.sourceId,
          name: food.name,
          brand: food.brand,
          calories_per_100g: food.caloriesPer100g,
          protein_per_100g: food.proteinPer100g,
          carbs_per_100g: food.carbsPer100g,
          fat_per_100g: food.fatPer100g,
          sugar_per_100g: food.sugarPer100g,
          fiber_per_100g: food.fiberPer100g,
          confidence: food.confidence,
          nutrition_quality_score: food.nutritionQualityScore,
          nutrition_quality_reason: food.nutritionQualityReason,
        },
        {
          onConflict: food.sourceId == null ? undefined : 'source,source_id',
          ignoreDuplicates: false,
        },
      )
      .select()
      .single()

    if (error) {
      throw error
    }

    return jsonResponse({ food: data }, 200)
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      400,
    )
  }
})

async function normalizeFood(payload: CatalogPayload): Promise<NormalizedFood> {
  const trimmedBarcode = payload.barcode?.trim() || ''
  const source = payload.source?.trim() || (trimmedBarcode.length > 0 ? 'shared_barcode' : 'shared_manual')
  const barcode = payload.barcode?.trim() || null

  if ((payload.name?.trim().length ?? 0) > 0) {
    const caloriesPer100g = toNullableNumber(payload.caloriesPer100g)
    const proteinPer100g = toNullableNumber(payload.proteinPer100g)
    const carbsPer100g = toNullableNumber(payload.carbsPer100g)
    const fatPer100g = toNullableNumber(payload.fatPer100g)
    const sugarPer100g = toNullableNumber(payload.sugarPer100g)
    const fiberPer100g = toNullableNumber(payload.fiberPer100g)
    const quality = calculateNutritionQualityScore({
      caloriesPer100g,
      proteinPer100g,
      carbsPer100g,
      fatPer100g,
      sugarPer100g,
      fiberPer100g,
      saturatedFatPer100g: null,
      sodiumMgPer100g: null,
    })

    return {
      source,
      sourceId: barcode,
      name: payload.name.trim(),
      brand: emptyToNull(payload.brand),
      caloriesPer100g,
      proteinPer100g,
      carbsPer100g,
      fatPer100g,
      sugarPer100g,
      fiberPer100g,
      confidence: 1,
      nutritionQualityScore: quality.score,
      nutritionQualityReason: quality.reason,
    }
  }

  if (payload.imageBase64) {
    const foodFromAi = await extractWithAi(payload)
    if (foodFromAi) {
      return {
        ...foodFromAi,
        source,
        sourceId: barcode,
      }
    }
  }

  if ((payload.ocrText?.trim().length ?? 0) > 0) {
    return parseFromOcrText(payload.ocrText, source, barcode)
  }

  throw new Error('Missing product data. Provide mapped fields, OCR text, or a label image.')
}

async function extractWithAi(payload: CatalogPayload): Promise<NormalizedFood | null> {
  if (!Deno.env.get('OPENROUTER_API_KEY')) {
    return null
  }

  const prompt = [
    'Extract a food label into JSON.',
    'Return only these fields: name, brand, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g, sugarPer100g, fiberPer100g, confidence.',
    'If a field is missing, return null.',
    'Use per 100g values whenever possible.',
  ].join(' ')

  try {
    const parsed = await callOpenRouterVisionJson({
      prompt,
      imageBase64: payload.imageBase64,
      maxTokens: 500,
    })

    if (!parsed.name) {
      return null
    }

    const quality = calculateNutritionQualityScore({
      caloriesPer100g: toNullableNumber(parsed.caloriesPer100g),
      proteinPer100g: toNullableNumber(parsed.proteinPer100g),
      carbsPer100g: toNullableNumber(parsed.carbsPer100g),
      fatPer100g: toNullableNumber(parsed.fatPer100g),
      sugarPer100g: toNullableNumber(parsed.sugarPer100g),
      fiberPer100g: toNullableNumber(parsed.fiberPer100g),
      saturatedFatPer100g: toNullableNumber(parsed.saturatedFatPer100g),
      sodiumMgPer100g: toNullableNumber(parsed.sodiumMgPer100g),
    })

    return {
      source: 'shared_ai',
      sourceId: null,
      name: String(parsed.name).trim(),
      brand: emptyToNull(parsed.brand),
      caloriesPer100g: quality.caloriesPer100g,
      proteinPer100g: quality.proteinPer100g,
      carbsPer100g: quality.carbsPer100g,
      fatPer100g: quality.fatPer100g,
      sugarPer100g: quality.sugarPer100g,
      fiberPer100g: quality.fiberPer100g,
      confidence: toNullableNumber(parsed.confidence) ?? 0.75,
      nutritionQualityScore:
          toNullableNumber(parsed.nutritionQualityScore) ?? quality.score,
      nutritionQualityReason:
          emptyToNull(parsed.nutritionQualityReason) ?? quality.reason,
    }
  } catch {
    return null
  }
}

function parseFromOcrText(
  ocrText: string,
  source: string,
  barcode: string | null,
): NormalizedFood {
  const lines = ocrText
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.length > 0)

  if (lines.length === 0) {
    throw new Error('OCR text is empty.')
  }

  const score = calculateNutritionQualityScore({
    caloriesPer100g: matchNumber(ocrText, ['kcal', 'calories', 'energy']),
    proteinPer100g: matchNumber(ocrText, ['protein', 'proteins']),
    carbsPer100g: matchNumber(ocrText, ['carbohydrate', 'carbohydrates', 'carbs']),
    fatPer100g: matchNumber(ocrText, ['fat', 'total fat']),
    sugarPer100g: matchNumber(ocrText, ['sugar', 'sugars']),
    fiberPer100g: matchNumber(ocrText, ['fiber', 'fibre']),
    saturatedFatPer100g: matchNumber(ocrText, ['saturated fat', 'saturates']),
    sodiumMgPer100g: matchNumber(ocrText, ['sodium', 'salt']),
  })

  return {
    source,
    sourceId: barcode,
    name: lines[0],
    brand: lines.length > 1 ? lines[1] : null,
    caloriesPer100g: score.caloriesPer100g,
    proteinPer100g: score.proteinPer100g,
    carbsPer100g: score.carbsPer100g,
    fatPer100g: score.fatPer100g,
    sugarPer100g: score.sugarPer100g,
    fiberPer100g: score.fiberPer100g,
    confidence: 0.55,
    nutritionQualityScore: score.score,
    nutritionQualityReason: score.reason,
  }
}

function calculateNutritionQualityScore(input: {
  caloriesPer100g: number | null
  proteinPer100g: number | null
  carbsPer100g: number | null
  fatPer100g: number | null
  sugarPer100g: number | null
  fiberPer100g: number | null
  saturatedFatPer100g: number | null
  sodiumMgPer100g: number | null
}) {
  let score = 2.5

  if ((input.proteinPer100g ?? 0) >= 20) {
    score += 1.1
  } else if ((input.proteinPer100g ?? 0) >= 10) {
    score += 0.5
  }

  if ((input.fiberPer100g ?? 0) >= 6) {
    score += 0.8
  } else if ((input.fiberPer100g ?? 0) >= 3) {
    score += 0.4
  }

  if ((input.sugarPer100g ?? 0) >= 20) {
    score -= 1.0
  } else if ((input.sugarPer100g ?? 0) >= 10) {
    score -= 0.5
  }

  if ((input.saturatedFatPer100g ?? 0) >= 8) {
    score -= 0.9
  } else if ((input.saturatedFatPer100g ?? 0) >= 4) {
    score -= 0.4
  }

  if ((input.sodiumMgPer100g ?? 0) >= 700) {
    score -= 0.8
  } else if ((input.sodiumMgPer100g ?? 0) >= 350) {
    score -= 0.3
  }

  if ((input.caloriesPer100g ?? 0) >= 450) {
    score -= 0.5
  }

  const clampedScore = Math.max(0, Math.min(5, Number(score.toFixed(1))))

  const reasonParts: string[] = []
  if ((input.proteinPer100g ?? 0) >= 10) {
    reasonParts.push('good protein')
  }
  if ((input.fiberPer100g ?? 0) >= 3) {
    reasonParts.push('useful fiber')
  }
  if ((input.sugarPer100g ?? 0) >= 10) {
    reasonParts.push('high sugar')
  }
  if ((input.saturatedFatPer100g ?? 0) >= 4) {
    reasonParts.push('high saturated fat')
  }
  if ((input.sodiumMgPer100g ?? 0) >= 350) {
    reasonParts.push('high salt/sodium')
  }

  return {
    ...input,
    score: clampedScore,
    reason: reasonParts.length > 0
      ? reasonParts.join(', ')
      : 'basic heuristic score from available nutrition data',
  }
}

function matchNumber(text: string, labels: string[]): number | null {
  for (const label of labels) {
    const regex = new RegExp(`${label}[^\d]{0,20}(\d+[\.,]?\d*)`, 'i')
    const match = text.match(regex)
    if (match?.[1]) {
      return Number(match[1].replace(',', '.'))
    }
  }

  return null
}

function emptyToNull(value: unknown): string | null {
  if (typeof value !== 'string') {
    return null
  }

  const trimmed = value.trim()
  return trimmed.length > 0 ? trimmed : null
}

function toNullableNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value
  }

  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value.replace(',', '.'))
    return Number.isFinite(parsed) ? parsed : null
  }

  return null
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
