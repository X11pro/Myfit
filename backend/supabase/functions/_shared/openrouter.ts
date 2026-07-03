<<<<<<< HEAD
type OpenRouterRequest = {
  prompt: string
  imageBase64: string
}

export async function callOpenRouterJson({
  prompt,
  imageBase64,
}: OpenRouterRequest): Promise<Record<string, unknown>> {
=======
const defaultSiteUrl = 'https://local.myfit.test'
const defaultAppName = 'Myfit'

type OpenRouterVisionRequest = {
  prompt: string
  imageBase64: string
  model?: string
  maxTokens?: number
}

export async function callOpenRouterVisionJson({
  prompt,
  imageBase64,
  model,
  maxTokens = 500,
}: OpenRouterVisionRequest): Promise<Record<string, unknown>> {
>>>>>>> efd4786 (Auto-sync project changes)
  const apiKey = Deno.env.get('OPENROUTER_API_KEY')
  if (!apiKey) {
    throw new Error('OPENROUTER_API_KEY is not configured in Supabase secrets.')
  }

<<<<<<< HEAD
  const model = Deno.env.get('OPENROUTER_MODEL') ?? 'qwen/qwen3-vl-8b-instruct'
=======
>>>>>>> efd4786 (Auto-sync project changes)
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
<<<<<<< HEAD
      'HTTP-Referer': 'https://github.com/X11pro/Myfit',
      'X-Title': 'Myfit',
    },
    body: JSON.stringify({
      model,
      temperature: 0.2,
      response_format: { type: 'json_object' },
=======
      'HTTP-Referer': Deno.env.get('OPENROUTER_SITE_URL') ?? defaultSiteUrl,
      'X-Title': Deno.env.get('OPENROUTER_APP_NAME') ?? defaultAppName,
    },
    body: JSON.stringify({
      model: model ?? Deno.env.get('OPENROUTER_MODEL') ?? 'qwen/qwen3-vl-8b-instruct',
>>>>>>> efd4786 (Auto-sync project changes)
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            {
              type: 'image_url',
              image_url: {
                url: `data:image/jpeg;base64,${imageBase64}`,
              },
            },
          ],
        },
      ],
<<<<<<< HEAD
=======
      max_tokens: maxTokens,
>>>>>>> efd4786 (Auto-sync project changes)
    }),
  })

  if (!response.ok) {
<<<<<<< HEAD
    const text = await response.text()
    throw new Error(`OpenRouter error: ${text}`)
  }

  const body = await response.json()
  const rawText = extractTextContent(body?.choices?.[0]?.message?.content)
  if (!rawText) {
    throw new Error('OpenRouter response did not include message content.')
  }

  const jsonText = extractJsonObject(rawText)
  return JSON.parse(jsonText) as Record<string, unknown>
}

function extractTextContent(content: unknown): string | null {
  if (typeof content === 'string') {
    return content.trim() || null
  }

  if (Array.isArray(content)) {
    const parts = content
      .map((item) => {
        if (typeof item === 'string') {
          return item
        }

        if (
          item &&
          typeof item === 'object' &&
          'text' in item &&
          typeof item.text === 'string'
        ) {
          return item.text
        }

        return ''
      })
      .join('\n')
      .trim()

    return parts || null
=======
    throw new Error(await response.text())
  }

  const body = await response.json()
  const rawText = extractTextContent(body)
  if (!rawText) {
    throw new Error('AI response did not include text content.')
  }

  const parsed = JSON.parse(stripJsonFences(rawText))
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('AI response JSON was not an object.')
  }

  return parsed as Record<string, unknown>
}

function extractTextContent(body: any): string | null {
  const content = body?.choices?.[0]?.message?.content
  if (typeof content === 'string') {
    return content
  }

  if (Array.isArray(content)) {
    const text = content
      .filter((part) => part?.type === 'text' && typeof part.text === 'string')
      .map((part) => part.text)
      .join('\n')
      .trim()

    return text.length > 0 ? text : null
>>>>>>> efd4786 (Auto-sync project changes)
  }

  return null
}

<<<<<<< HEAD
function extractJsonObject(text: string): string {
  const trimmed = text.trim()
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    return trimmed
  }

  const fencedMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)\s*```/i)
  if (fencedMatch?.[1]) {
    return fencedMatch[1].trim()
  }

  const firstBrace = trimmed.indexOf('{')
  const lastBrace = trimmed.lastIndexOf('}')
  if (firstBrace >= 0 && lastBrace > firstBrace) {
    return trimmed.slice(firstBrace, lastBrace + 1)
  }

  return trimmed
=======
function stripJsonFences(value: string): string {
  const trimmed = value.trim()
  if (!trimmed.startsWith('```')) {
    return trimmed
  }

  return trimmed
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '')
    .trim()
>>>>>>> efd4786 (Auto-sync project changes)
}
