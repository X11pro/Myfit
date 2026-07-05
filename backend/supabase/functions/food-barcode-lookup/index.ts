import { createClient } from 'npm:@supabase/supabase-js@2'

type BarcodeLookupPayload = {
  barcode?: string
}

type CachedFood = {
  id: string
  source: string
  source_id: string | null
  name: string
  brand: string | null
  calories_per_100g: number | null
  protein_per_100g: number | null
  carbs_per_100g: number | null
  fat_per_100g: number | null
  sugar_per_100g: number | null
  fiber_per_100g: number | null
  confidence: number | null
  nutrition_quality_score?: number | null
  nutrition_quality_reason?: string | null
}

type NormalizedFood = {
  source: string
  sourceId: string
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
    const payload = (await request.json()) as BarcodeLookupPayload
    const barcode = payload.barcode?.trim() ?? ''

    if (barcode.length < 8) {
      throw new Error('Barcode is required and must be at least 8 digits.')
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('Missing Supabase service role configuration.')
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey)
    const cachedFood = await findCachedFood(supabase, barcode)
    if (cachedFood) {
      return jsonResponse({ food: mapCachedFood(cachedFood), cached: true }, 200)
    }

    const fetchedFood = await fetchOpenFoodFacts(barcode)
    const resolvedFood = fetchedFood ?? await fetchUsdaFoodDataCentral(barcode)

    if (!resolvedFood) {
      return jsonResponse({ food: null, cached: false }, 200)
    }

    const persistedFood = await persistFood(supabase, resolvedFood)

    return jsonResponse({ food: mapCachedFood(persistedFood), cached: false }, 200)
  } catch (error) {
    return jsonResponse(
      { error: describeError(error) },
      400,
    )
  }
})

async function findCachedFood(supabase: ReturnType<typeof createClient>, barcode: string) {
  const { data, error } = await supabase
    .from('food_items')
    .select(
      'id, source, source_id, name, brand, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, sugar_per_100g, fiber_per_100g, confidence, nutrition_quality_score, nutrition_quality_reason',
    )
    .eq('source_id', barcode)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()

  if (error) {
    throw error
  }

  return data as CachedFood | null
}

async function persistFood(
  supabase: ReturnType<typeof createClient>,
  food: NormalizedFood,
) {
  const payload = {
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
  }

  const { data: existing, error: existingError } = await supabase
    .from('food_items')
    .select(
      'id, source, source_id, name, brand, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, sugar_per_100g, fiber_per_100g, confidence, nutrition_quality_score, nutrition_quality_reason',
    )
    .eq('source', food.source)
    .eq('source_id', food.sourceId)
    .limit(1)
    .maybeSingle()

  if (existingError) {
    throw existingError
  }

  if (existing) {
    const { data, error } = await supabase
      .from('food_items')
      .update(payload)
      .eq('id', existing.id)
      .select(
        'id, source, source_id, name, brand, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, sugar_per_100g, fiber_per_100g, confidence, nutrition_quality_score, nutrition_quality_reason',
      )
      .single()

    if (error) {
      throw error
    }

    return data as CachedFood
  }

  const { data, error } = await supabase
    .from('food_items')
    .insert(payload)
    .select(
      'id, source, source_id, name, brand, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, sugar_per_100g, fiber_per_100g, confidence, nutrition_quality_score, nutrition_quality_reason',
    )
    .single()

  if (error) {
    throw error
  }

  return data as CachedFood
}

async function fetchOpenFoodFacts(barcode: string): Promise<NormalizedFood | null> {
  const response = await fetch(`https://world.openfoodfacts.org/api/v2/product/${barcode}.json`)
  if (!response.ok) {
    throw new Error(`Open Food Facts lookup failed with status ${response.status}.`)
  }

  const payload = await response.json()
  const product = payload?.product
  if (!product || payload?.status !== 1) {
    return null
  }

  const nutriments = product.nutriments ?? {}
  const name = firstNonEmptyString([
    product.product_name,
    product.product_name_en,
    product.generic_name,
  ])

  if (!name) {
    return null
  }

  const caloriesPer100g = toKcal(nutriments['energy-kcal_100g'] ?? nutriments.energy_kcal_100g)
  const proteinPer100g = toNullableNumber(nutriments.proteins_100g)
  const carbsPer100g = toNullableNumber(nutriments.carbohydrates_100g)
  const fatPer100g = toNullableNumber(nutriments.fat_100g)
  const sugarPer100g = toNullableNumber(nutriments.sugars_100g)
  const fiberPer100g = toNullableNumber(nutriments.fiber_100g)

  const quality = calculateNutritionQualityScore({
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    sugarPer100g,
    fiberPer100g,
    saturatedFatPer100g: toNullableNumber(nutriments['saturated-fat_100g']),
    sodiumMgPer100g: toSodiumMilligrams(
      nutriments.sodium_100g,
      nutriments.salt_100g,
    ),
  })

  return {
    source: 'open_food_facts',
    sourceId: barcode,
    name,
    brand: firstNonEmptyString([product.brands, product.brand_owner]),
    caloriesPer100g: quality.caloriesPer100g,
    proteinPer100g: quality.proteinPer100g,
    carbsPer100g: quality.carbsPer100g,
    fatPer100g: quality.fatPer100g,
    sugarPer100g: quality.sugarPer100g,
    fiberPer100g: quality.fiberPer100g,
    confidence: 0.94,
    nutritionQualityScore: quality.score,
    nutritionQualityReason: quality.reason,
  }
}

async function fetchUsdaFoodDataCentral(barcode: string): Promise<NormalizedFood | null> {
  const apiKey = Deno.env.get('USDA_FDC_API_KEY')
  if (!apiKey) {
    return null
  }

  const response = await fetch(
    `https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${encodeURIComponent(apiKey)}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: barcode,
        dataType: ['Branded'],
        pageSize: 10,
      }),
    },
  )

  if (!response.ok) {
    throw new Error(`USDA lookup failed with status ${response.status}.`)
  }

  const payload = await response.json()
  const foods = Array.isArray(payload?.foods) ? payload.foods : []
  const matchedFood = foods.find((food) => {
    const gtinUpc = food?.gtinUpc?.toString().trim()
    return gtinUpc === barcode
  })

  if (!matchedFood) {
    return null
  }

  const caloriesPer100g = nutrientValue(matchedFood.foodNutrients, [
    'Energy',
    'Energy (Atwater General Factors)',
  ])
  const proteinPer100g = nutrientValue(matchedFood.foodNutrients, ['Protein'])
  const carbsPer100g = nutrientValue(matchedFood.foodNutrients, [
    'Carbohydrate, by difference',
  ])
  const fatPer100g = nutrientValue(matchedFood.foodNutrients, ['Total lipid (fat)'])
  const sugarPer100g = nutrientValue(matchedFood.foodNutrients, [
    'Sugars, total including NLEA',
    'Sugars, total',
  ])
  const fiberPer100g = nutrientValue(matchedFood.foodNutrients, [
    'Fiber, total dietary',
  ])
  const saturatedFatPer100g = nutrientValue(matchedFood.foodNutrients, [
    'Fatty acids, total saturated',
  ])
  const sodiumMgPer100g = nutrientValue(matchedFood.foodNutrients, ['Sodium, Na'])

  const quality = calculateNutritionQualityScore({
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    sugarPer100g,
    fiberPer100g,
    saturatedFatPer100g,
    sodiumMgPer100g,
  })

  const description = firstNonEmptyString([
    matchedFood.description,
    matchedFood.lowercaseDescription,
  ])
  if (!description) {
    return null
  }

  return {
    source: 'usda',
    sourceId: String(matchedFood.fdcId ?? barcode),
    name: description,
    brand: firstNonEmptyString([
      matchedFood.brandOwner,
      matchedFood.brandName,
      matchedFood.brandOwner,
    ]),
    caloriesPer100g: quality.caloriesPer100g,
    proteinPer100g: quality.proteinPer100g,
    carbsPer100g: quality.carbsPer100g,
    fatPer100g: quality.fatPer100g,
    sugarPer100g: quality.sugarPer100g,
    fiberPer100g: quality.fiberPer100g,
    confidence: 0.88,
    nutritionQualityScore: quality.score,
    nutritionQualityReason: quality.reason,
  }
}

function mapCachedFood(food: CachedFood) {
  return {
    id: food.id,
    source: food.source,
    sourceId: food.source_id,
    name: food.name,
    brand: food.brand,
    caloriesPer100g: toNullableNumber(food.calories_per_100g),
    proteinPer100g: toNullableNumber(food.protein_per_100g),
    carbsPer100g: toNullableNumber(food.carbs_per_100g),
    fatPer100g: toNullableNumber(food.fat_per_100g),
    sugarPer100g: toNullableNumber(food.sugar_per_100g),
    fiberPer100g: toNullableNumber(food.fiber_per_100g),
    confidence: toNullableNumber(food.confidence) ?? 0.9,
    nutritionQualityScore: toNullableNumber(food.nutrition_quality_score),
    nutritionQualityReason: emptyToNull(food.nutrition_quality_reason),
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

function describeError(error: unknown) {
  if (error instanceof Error) {
    return error.message
  }

  if (typeof error === 'string' && error.trim().length > 0) {
    return error
  }

  try {
    return JSON.stringify(error)
  } catch {
    return 'Unknown error'
  }
}

function firstNonEmptyString(values: unknown[]): string | null {
  for (const value of values) {
    if (typeof value === 'string' && value.trim().length > 0) {
      return value.trim()
    }
  }

  return null
}

function emptyToNull(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : null
}

function toNullableNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value
  }

  if (typeof value === 'string') {
    const parsed = Number.parseFloat(value.replace(',', '.'))
    return Number.isFinite(parsed) ? parsed : null
  }

  return null
}

function toKcal(value: unknown): number | null {
  const direct = toNullableNumber(value)
  return direct == null ? null : direct
}

function toSodiumMilligrams(sodium100g: unknown, salt100g: unknown): number | null {
  const sodium = toNullableNumber(sodium100g)
  if (sodium != null) {
    return sodium * 1000
  }

  const salt = toNullableNumber(salt100g)
  if (salt != null) {
    return salt * 400
  }

  return null
}

function nutrientValue(foodNutrients: unknown, names: string[]): number | null {
  if (!Array.isArray(foodNutrients)) {
    return null
  }

  for (const nutrient of foodNutrients) {
    const nutrientName = typeof nutrient?.nutrientName === 'string'
      ? nutrient.nutrientName.trim()
      : ''
    if (!names.includes(nutrientName)) {
      continue
    }

    const value = toNullableNumber(nutrient?.value)
    if (value != null) {
      return value
    }
  }

  return null
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
  let score = 3
  const reasons: string[] = []

  if ((input.proteinPer100g ?? 0) >= 10) {
    score += 0.5
    reasons.push('good protein per 100g')
  }

  if ((input.fiberPer100g ?? 0) >= 3) {
    score += 0.5
    reasons.push('good fiber per 100g')
  }

  if ((input.sugarPer100g ?? 0) >= 15) {
    score -= 0.5
    reasons.push('high sugar per 100g')
  }

  if ((input.saturatedFatPer100g ?? 0) >= 5) {
    score -= 0.5
    reasons.push('high saturated fat per 100g')
  }

  if ((input.sodiumMgPer100g ?? 0) >= 600) {
    score -= 0.5
    reasons.push('high sodium per 100g')
  }

  return {
    ...input,
    score: Math.max(0, Math.min(5, Number(score.toFixed(1)))),
    reason: reasons.length > 0 ? reasons.join(', ') : 'balanced baseline from available nutrition data',
  }
}
