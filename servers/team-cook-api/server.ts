import type { BunRequest } from 'bun'
import { Database } from 'bun:sqlite'
import chalk from 'chalk'

const CACHE_DURATION_MS_DEFAULT = 1000 * 60 * 60 * 24 // 24 hours

// Cache database
const cacheDb = new Database('cache.sqlite')
cacheDb.run(`
  CREATE TABLE IF NOT EXISTS cache (
    key TEXT PRIMARY KEY,
    value TEXT,
    expires_at INTEGER
  )
  `)

// Read CSV to find max ingredient ID (for assigning new IDs to unknown ingredients)
const csvContent = await Bun.file('ingredients-with-possible-units.csv').text()
const lines = csvContent.trim().split('\n')

let maxIngredientId = 0
for (const line of lines) {
  const parts = line.split(';')
  const idStr = parts[1]
  if (!idStr) continue
  const id = parseInt(idStr, 10)
  if (!isNaN(id) && id > maxIngredientId) {
    maxIngredientId = id
  }
}

// Counter for assigning new ingredient IDs (in memory only, resets on restart)
let nextIngredientId = maxIngredientId + 1
console.log(
  chalk.cyan('[INIT]'),
  `Max ingredient ID from CSV: ${maxIngredientId}, next ID will be: ${nextIngredientId}`,
)

const getCache = cacheDb.prepare<{ value: string }, [key: string, expiresAt: number]>(
  `SELECT value FROM cache WHERE key = ? AND expires_at > ?`,
)
const setCache = cacheDb.prepare<void, [key: string, value: string, expiresAt: number]>(
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

// Types for ingredient processing
interface Measure {
  amount: number
  unitShort: string
  unitLong: string
}

interface Ingredient {
  id: number
  name: string
  originalName: string
  measures?: {
    us?: Measure
    metric?: Measure
  }
}

interface Recipe {
  id: number
  extendedIngredients?: Ingredient[]
}

// In-memory map of ingredient names to assigned IDs (for ingredients with id=-1)
const assignedIngredientIds = new Map<string, number>()

/**
 * Process extendedIngredients to assign IDs to ingredients with id=-1
 * Deduplicates by name+originalName combination and assigns new IDs in memory
 * Mutates the ingredients array in place
 */
function processNewIngredients(extendedIngredients: Ingredient[]): void {
  for (const ing of extendedIngredients) {
    if (ing.id !== -1) continue

    // Create dedupe key from name + originalName
    const key = `${ing.name.toLowerCase()}|${ing.originalName.toLowerCase()}`

    // Check if we've already assigned an ID for this ingredient
    let assignedId = assignedIngredientIds.get(key)
    if (assignedId === undefined) {
      // Assign new ID
      assignedId = nextIngredientId++
      assignedIngredientIds.set(key, assignedId)
      console.log(chalk.green('[INGREDIENT]'), `Assigned new ID ${assignedId} to "${ing.name}"`)
    }

    // Mutate the ingredient with the assigned ID
    ing.id = assignedId
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
        const body = await response.json()
        if (typeof body === 'object' && body != null && 'recipes' in body) {
          const recipes = body.recipes as Recipe[]
          for (const recipe of recipes) {
            // Process new ingredients (those with id=-1) - mutates in place
            if (recipe.extendedIngredients) {
              processNewIngredients(recipe.extendedIngredients)
            }

            // Cache individual recipe
            if (typeof recipe.id === 'number') {
              const cacheKey = `/api/1/recipes/${recipe.id}/information`
              setCache.run(cacheKey, JSON.stringify(recipe), Date.now() + CACHE_DURATION_MS_DEFAULT)
            }
          }
        }
        // Return modified response with updated ingredient IDs
        return new Response(JSON.stringify(body), {
          status: response.status,
          headers: { 'Content-Type': 'application/json' },
        })
      },
    }),
    '/api/1/recipes/:id/information': proxySpoonacularRequest('/recipes/:id/information', {
      processResponse: async (response) => {
        const recipe = (await response.json()) as Recipe
        // Process new ingredients (those with id=-1) - mutates in place
        if (recipe.extendedIngredients) {
          processNewIngredients(recipe.extendedIngredients)
        }
        // Return modified response with updated ingredient IDs
        return new Response(JSON.stringify(recipe), {
          status: response.status,
          headers: { 'Content-Type': 'application/json' },
        })
      },
    }),
    '/api/1/recipes/by-ingredients': proxySpoonacularRequest('/recipes/findByIngredients'),
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
