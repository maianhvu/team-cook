import { Database } from 'bun:sqlite'

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

interface ProxySpoonacularRequestOptions {
  cacheDurationMs?: number
}

const proxySpoonacularRequest = (
  endpoint: string | ((requestUrl: URL) => string),
  options?: ProxySpoonacularRequestOptions,
) => {
  const { cacheDurationMs = CACHE_DURATION_MS_DEFAULT } = options ?? {}

  return async (req: Request): Promise<Response> => {
    const apiKey = Bun.env.SPOONACULAR_API_KEY
    if (!apiKey) {
      return new Response('API key is not set', { status: 500 })
    }
    const requestUrl = new URL(req.url)

    const cacheKey = `${requestUrl.pathname}${requestUrl.search}`
    if (!req.headers.get('Cache-Control')?.includes('no-cache')) {
      const cached = getCache.get(cacheKey, Date.now())
      if (cached) {
        return new Response(cached.value, {
          headers: { 'Content-Type': 'application/json', 'X-Cache': 'HIT' },
        })
      }
    }

    const proxiedUrl = new URL('https://api.spoonacular.com/')
    proxiedUrl.pathname = typeof endpoint === 'function' ? endpoint(requestUrl) : endpoint
    proxiedUrl.searchParams.set('apiKey', apiKey)
    // Forward all query parameters to the Spoonacular API
    for (const [param, value] of requestUrl.searchParams.entries()) {
      proxiedUrl.searchParams.set(param, value)
    }
    const response = await fetch(proxiedUrl.toString())
    if (!response.ok) {
      return response
    }

    const body = await response.text()
    setCache.run(cacheKey, body, Date.now() + cacheDurationMs)

    // Create a new Response since fetch response headers are immutable
    const responseHeaders = new Headers(response.headers)
    responseHeaders.set('X-Cache', 'MISS')
    return new Response(body, { status: response.status, headers: responseHeaders })
  }
}

const server = Bun.serve({
  routes: {
    '/api/status': new Response('OK'),
    '/api/1/recipes/random': proxySpoonacularRequest('/recipes/random'),
  },
  fetch() {
    return new Response('Not Found', { status: 404 })
  },
})

console.log(`🌏 Server is running at ${server.url}`)
