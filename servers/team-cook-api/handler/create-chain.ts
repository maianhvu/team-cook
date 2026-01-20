import type { BunRequest } from 'bun'
import type { Handler, Next } from './types'

/**
 * Convert a route pattern like '/api/1/recipes/:id/information' to a regex
 * and extract parameter names
 */
function patternToRegex(pattern: string): { regex: RegExp; paramNames: string[] } {
  const paramNames: string[] = []
  const regexPattern = pattern.replace(/:([^/]+)/g, (_match, paramName) => {
    paramNames.push(paramName)
    return '([^/]+)'
  })
  return {
    regex: new RegExp(`^${regexPattern}$`),
    paramNames,
  }
}

/**
 * Try to match a path against a route pattern
 * Returns params if matched, null otherwise
 */
function matchRoute(path: string, pattern: string): Record<string, string> | null {
  const { regex, paramNames } = patternToRegex(pattern)
  const match = path.match(regex)
  if (!match) return null

  const params: Record<string, string> = {}
  paramNames.forEach((name, index) => {
    const value = match[index + 1]
    if (value !== undefined) {
      params[name] = value
    }
  })
  return params
}

/**
 * Find the first matching route in a handler's routes
 */
function findRouteMatch(
  handler: Handler,
  pathname: string,
): { pattern: string; params: Record<string, string> } | null {
  if (!handler.routes) return null

  for (const pattern of Object.keys(handler.routes)) {
    const params = matchRoute(pathname, pattern)
    if (params !== null) {
      return { pattern, params }
    }
  }
  return null
}

/**
 * Create a handler chain that processes requests through multiple handlers
 */
export function createHandlerChain(handlers: Handler[]): {
  fetch: (req: Request) => Promise<Response>
} {
  const fetch = async (req: Request): Promise<Response> => {
    const url = new URL(req.url)
    const pathname = url.pathname

    // Create the chain execution function
    const executeChain = async (handlerIndex: number): Promise<Response> => {
      // If we've exhausted all handlers, return 404
      if (handlerIndex >= handlers.length) {
        return new Response('Not Found', { status: 404 })
      }

      const handler = handlers[handlerIndex]!
      const next: Next = () => executeChain(handlerIndex + 1)

      // First, try to match against handler's routes
      const routeMatch = findRouteMatch(handler, pathname)
      if (routeMatch && handler.routes) {
        const routeHandler = handler.routes[routeMatch.pattern]
        if (routeHandler) {
          // Create a BunRequest-like object with params attached
          const reqWithParams = req as BunRequest<string>
          ;(reqWithParams as any).params = routeMatch.params
          return routeHandler(reqWithParams as any, next)
        }
      }

      // If no route matched, try the fetch handler
      if (handler.fetch) {
        return handler.fetch(req, next)
      }

      // No route and no fetch, pass to next handler
      return next()
    }

    return executeChain(0)
  }

  return { fetch }
}
