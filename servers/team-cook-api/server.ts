import type { BunRequest } from 'bun'
import { Database } from 'bun:sqlite'
import chalk from 'chalk'

const CACHE_DURATION_MS_DEFAULT = 1000 * 60 * 60 * 24 // 24 hours

const db = new Database('cache.sqlite')
db.run(`
  CREATE TABLE IF NOT EXISTS cache (
    key TEXT PRIMARY KEY,
    value TEXT,
    expires_at INTEGER
  )
  `)

const getCache = db.prepare<{ value: string }, [key: string, expiresAt: number]>(
  `SELECT value FROM cache WHERE key = ? AND expires_at > ?`,
)
const setCache = db.prepare<void, [key: string, value: string, expiresAt: number]>(
  `INSERT OR REPLACE INTO cache (key, value, expires_at) VALUES (?, ?, ?)`,
)

function requestMethodTag(method: string): string {
  switch (method) {
    case 'GET':
      return chalk.green('[GET]')
    case 'POST':
      return chalk.blue('[POST]')
    case 'PUT':
      return chalk.yellow('[PUT]')
    case 'DELETE':
      return chalk.red('[DELETE]')
    case 'PATCH':
      return chalk.magenta('[PATCH]')
    default:
      return chalk.white(`[${method.toUpperCase()}]`)
  }
}

interface ProxySpoonacularRequestOptions {
  cacheDurationMs?: number
  processResponse?: (response: Response) => Response | Promise<Response>
}

const proxySpoonacularRequest = (
  endpoint: string | ((requestUrl: URL) => string),
  options?: ProxySpoonacularRequestOptions,
) => {
  const { cacheDurationMs = CACHE_DURATION_MS_DEFAULT } = options ?? {}

  return async (req: BunRequest<string>): Promise<Response> => {
    const apiKey = Bun.env.SPOONACULAR_API_KEY
    if (!apiKey) {
      throw new Error('API key is not set')
    }
    try {
      const requestUrl = new URL(req.url)

      const cacheKey = `${requestUrl.pathname}${requestUrl.search}`
      if (!req.headers.get('Cache-Control')?.includes('no-cache')) {
        const cached = getCache.get(cacheKey, Date.now())
        if (cached) {
          console.log(requestMethodTag(req.method), requestUrl.pathname, '->', chalk.green('(cache hit)'))
          return new Response(cached.value, {
            headers: { 'Content-Type': 'application/json', 'X-Cache': 'HIT' },
          })
        }
      }

      const proxiedUrl = new URL('https://api.spoonacular.com/')
      proxiedUrl.pathname = typeof endpoint === 'function' ? endpoint(requestUrl) : endpoint
      proxiedUrl.pathname = proxiedUrl.pathname.replace(
        /:([^/]+)/g,
        (_match, paramName) => req.params[paramName] as string,
      )

      proxiedUrl.searchParams.set('apiKey', apiKey)
      // Forward all query parameters to the Spoonacular API
      for (const [param, value] of requestUrl.searchParams.entries()) {
        proxiedUrl.searchParams.set(param, value)
      }
      const unprocessedResponse = await fetch(proxiedUrl.toString())
      if (!unprocessedResponse.ok) {
        console.log(
          requestMethodTag(req.method),
          requestUrl.pathname,
          '->',
          chalk.red(`${unprocessedResponse.status} ${unprocessedResponse.statusText}`),
        )
        return unprocessedResponse
      }

      const response = (await options?.processResponse?.(unprocessedResponse)) ?? unprocessedResponse

      const body = await response.text()
      setCache.run(cacheKey, body, Date.now() + cacheDurationMs)

      // Create a new Response since fetch response headers are immutable
      const responseHeaders = new Headers(response.headers)
      responseHeaders.set('X-Cache', 'MISS')

      console.log(
        requestMethodTag(req.method),
        requestUrl.pathname,
        '->',
        proxiedUrl.pathname,
        chalk.yellow('(cache miss)'),
      )
      return new Response(body, { status: response.status, headers: responseHeaders })
    } catch (error) {
      return new Response(error instanceof Error ? error.message : String(error), { status: 500 })
    }
  }
}

const server = Bun.serve({
  routes: {
    '/api/status': new Response('OK'),
    '/api/1/recipes/random': proxySpoonacularRequest('/recipes/random', {
      processResponse: async (response) => {
        const clonedResponse = response.clone()
        const body = await clonedResponse.json()
        if (typeof body === 'object' && body != null && 'recipes' in body) {
          const recipes = body.recipes as { id: number }[]
          for (const recipe of recipes) {
            if (typeof recipe.id !== 'number') continue
            const cacheKey = `/api/1/recipes/${recipe.id}/information`
            setCache.run(cacheKey, JSON.stringify(recipe), Date.now() + CACHE_DURATION_MS_DEFAULT)
          }
        }
        // Preserve original response
        return response
      },
    }),
    '/api/1/recipes/:id/information': proxySpoonacularRequest('/recipes/:id/information'),
  },
  fetch(req) {
    console.log(requestMethodTag(req.method), new URL(req.url).pathname, '->', chalk.dim('404'))
    return new Response('Not Found', { status: 404 })
  },
  error(error) {
    console.error(chalk.red('[ERROR]'), error)
    return new Response('Internal Server Error', { status: 500 })
  },
})

console.log(`🌏 Server is running at ${server.url}`)
