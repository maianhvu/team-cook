import { Database } from 'bun:sqlite'

export const CACHE_DURATION_MS_DEFAULT = 1000 * 60 * 60 * 24 // 24 hours

// Cache database
const cacheDb = new Database('cache.sqlite')
cacheDb.run(`
  CREATE TABLE IF NOT EXISTS cache (
    key TEXT PRIMARY KEY,
    value TEXT,
    expires_at INTEGER
  )
`)

const getCacheStmt = cacheDb.prepare<{ value: string }, [key: string, expiresAt: number]>(
  `SELECT value FROM cache WHERE key = ? AND expires_at > ?`,
)
const setCacheStmt = cacheDb.prepare<void, [key: string, value: string, expiresAt: number]>(
  `INSERT OR REPLACE INTO cache (key, value, expires_at) VALUES (?, ?, ?)`,
)

/**
 * Get a cached value by key
 * Returns the cached value or null if not found or expired
 */
export function getCache(key: string): string | null {
  const result = getCacheStmt.get(key, Date.now())
  return result?.value ?? null
}

/**
 * Set a cached value with expiration
 */
export function setCache(key: string, value: string, durationMs: number = CACHE_DURATION_MS_DEFAULT): void {
  setCacheStmt.run(key, value, Date.now() + durationMs)
}
