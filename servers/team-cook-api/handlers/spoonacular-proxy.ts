import chalk from 'chalk'
import { defineHandler } from '../handler/types'
import { requestMethodTag } from '../utils/logging'

/**
 * Proxy a request to the Spoonacular API
 */
async function proxyToSpoonacular(req: Request, endpoint: string): Promise<Response> {
  const apiKey = Bun.env.SPOONACULAR_API_KEY
  if (!apiKey) {
    throw new Error('SPOONACULAR_API_KEY is not set')
  }

  const requestUrl = new URL(req.url)
  const proxiedUrl = new URL('https://api.spoonacular.com/')
  proxiedUrl.pathname = endpoint

  // Add API key
  proxiedUrl.searchParams.set('apiKey', apiKey)

  // Forward all query parameters to the Spoonacular API
  for (const [param, value] of requestUrl.searchParams.entries()) {
    proxiedUrl.searchParams.set(param, value)
  }

  const response = await fetch(proxiedUrl.toString())

  if (!response.ok) {
    console.log(
      requestMethodTag(req.method),
      requestUrl.pathname,
      '->',
      chalk.red(`${response.status} ${response.statusText}`),
    )
  } else {
    console.log(requestMethodTag(req.method), requestUrl.pathname, '->', proxiedUrl.pathname, chalk.cyan('(proxied)'))
  }

  return response
}

export const spoonacularProxy = defineHandler({
  name: 'spoonacular-proxy',

  routes: {
    '/api/1/recipes/random': (req) => {
      return proxyToSpoonacular(req, '/recipes/random')
    },
    '/api/1/recipes/:id/information': (req) => {
      // req.params.id is typed as string
      return proxyToSpoonacular(req, `/recipes/${req.params.id}/information`)
    },
    '/api/1/recipes/by-ingredients': (req) => {
      return proxyToSpoonacular(req, '/recipes/findByIngredients')
    },
  },
})
