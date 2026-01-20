import chalk from 'chalk'
import { createHandlerChain } from './handler/create-chain'
import { cacheHandler } from './handlers/cache'
import { ingredientProcessor } from './handlers/ingredient-processor'
import { spoonacularProxy } from './handlers/spoonacular-proxy'
import { requestMethodTag } from './utils/logging'

const chain = createHandlerChain([cacheHandler, ingredientProcessor, spoonacularProxy])

const server = Bun.serve({
  routes: {
    // Static routes that don't need the handler chain
    '/api/status': new Response('OK'),
  },
  fetch: (req) => {
    // Log 404s for routes not handled by the chain
    return chain.fetch(req).then((response) => {
      if (response.status === 404) {
        console.log(requestMethodTag(req.method), new URL(req.url).pathname, '->', chalk.dim('404'))
      }
      return response
    })
  },
  error: (error) => {
    console.error(chalk.red('[ERROR]'), error)
    return new Response('Internal Server Error', { status: 500 })
  },
})

console.log(`🌏 Server is running at ${server.url}`)
