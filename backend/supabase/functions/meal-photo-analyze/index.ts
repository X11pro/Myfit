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

    const apiKey = Deno.env.get('OPENAI_API_KEY')
    if (!apiKey) {
      return jsonResponse(
        { error: 'OPENAI_API_KEY is not configured in Supabase secrets.' },
        503,
      )
    }

    const prompt = [
      'Analyze the meal photo and estimate a simple nutrition summary.',
      'Return JSON only with these fields:',
      'name, estimatedMealType, estimatedCalories, estimatedProteinGrams, estimatedCarbsGrams, estimatedFatGrams, confidence, notes.',
      'Confidence must be a number between 0 and 1.',
      'Keep the answer conservative and practical.',
    ].join(' ')

    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: Deno.env.get('OPENAI_MODEL') ?? 'gpt-4.1-mini',
        input: [
          {
            role: 'user',
            content: [
              { type: 'input_text', text: prompt },
              {
                type: 'input_image',
                image_url: `data:image/jpeg;base64,${payload.imageBase64}`,
              },
            ],
          },
        ],
      }),
    })

    if (!response.ok) {
      const text = await response.text()
      return jsonResponse({ error: text }, 502)
    }

    const body = await response.json()
    const rawText = body.output_text as string | undefined
    if (!rawText) {
      return jsonResponse({ error: 'AI response did not include output_text.' }, 502)
    }

    const parsed = JSON.parse(rawText)
    const analysis: MealAnalysis = {
      name: String(parsed.name ?? 'Unknown meal').trim(),
      estimatedMealType: stringOrNull(parsed.estimatedMealType),
      estimatedCalories: numberOrNull(parsed.estimatedCalories),
      estimatedProteinGrams: numberOrNull(parsed.estimatedProteinGrams),
      estimatedCarbsGrams: numberOrNull(parsed.estimatedCarbsGrams),
      estimatedFatGrams: numberOrNull(parsed.estimatedFatGrams),
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
