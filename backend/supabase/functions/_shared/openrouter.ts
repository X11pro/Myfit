type OpenRouterRequest = {
  prompt: string
  imageBase64: string
}

export async function callOpenRouterJson({
  prompt,
  imageBase64,
}: OpenRouterRequest): Promise<Record<string, unknown>> {
  const apiKey = Deno.env.get('OPENROUTER_API_KEY')
  if (!apiKey) {
    throw new Error('OPENROUTER_API_KEY is not configured in Supabase secrets.')
  }

  const model = Deno.env.get('OPENROUTER_MODEL') ?? 'qwen/qwen3-vl-8b-instruct'
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://github.com/X11pro/Myfit',
      'X-Title': 'Myfit',
    },
    body: JSON.stringify({
      model,
      temperature: 0.2,
      response_format: { type: 'json_object' },
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
    }),
  })

  if (!response.ok) {
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
  }

  return null
}

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
}
