import type { BunRequest } from 'bun'

export type Next = () => Promise<Response>

/** Route handler function - receives BunRequest with typed params */
export type RouteHandler<T extends string> = (
  req: BunRequest<T>,
  next: Next
) => Response | Promise<Response>

/**
 * Routes object where each key maps to a handler with typed params.
 * The generic R captures the union of all route patterns as literal types.
 */
export type Routes<R extends string> = {
  [Path in R]: RouteHandler<Path>
}

export interface Handler<R extends string = string> {
  /** Human-readable name for logging */
  name: string

  /**
   * Optional: Typed route handlers (like Bun.serve routes)
   * Each route pattern gives you typed params via BunRequest<pattern>
   */
  routes?: Routes<R>

  /**
   * Optional: Catch-all for routes not declared in `routes`
   * Called when request doesn't match any pattern in this handler's routes
   */
  fetch?: (req: Request, next: Next) => Response | Promise<Response>
}

/**
 * Helper function to define a handler with proper type inference for routes.
 * This ensures route patterns like '/api/1/recipes/:id' give you typed req.params.id
 */
export function defineHandler<R extends string = never>(
  handler: Handler<R>,
): Handler<R> {
  return handler
}
