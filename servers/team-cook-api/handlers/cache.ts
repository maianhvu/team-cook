import chalk from 'chalk'
import { defineHandler } from '../handler/types'
import { getCache, setCache, CACHE_DURATION_MS_DEFAULT } from '../services/cache'
import { requestMethodTag } from '../utils/logging'

export const cacheHandler = defineHandler({
  name: 'cache',

  // Uses fetch to catch all /api/1/recipes/* routes
  fetch: async (req, next) => {
    const url = new URL(req.url)

    // Only cache recipe routes
    if (!url.pathname.startsWith('/api/1/recipes')) {
      return next() // Not a recipe route, pass through
    }

    // Check for no-cache header
    const bypassCache = req.headers.get('Cache-Control')?.includes('no-cache')

    const cacheKey = `${url.pathname}${url.search}`

    if (!bypassCache) {
      const cached = getCache(cacheKey)
      if (cached) {
        console.log(requestMethodTag(req.method), url.pathname, '->', chalk.green('(cache hit)'))
        return new Response(cached, {
          headers: { 'Content-Type': 'application/json', 'X-Cache': 'HIT' },
        })
      }
    }

    // Cache miss, get response from next handler
    const response = await next()

    // Only cache successful responses
    if (response.ok) {
      const body = await response.text()
      setCache(cacheKey, body, CACHE_DURATION_MS_DEFAULT)

      // Create a new Response since we've consumed the body
      const responseHeaders = new Headers(response.headers)
      responseHeaders.set('X-Cache', 'MISS')

      console.log(requestMethodTag(req.method), url.pathname, '->', chalk.yellow('(cache miss)'))

      return new Response(body, {
        status: response.status,
        headers: responseHeaders,
      })
    }

    return response
  },
})
