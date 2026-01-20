import { defineHandler } from '../handler/types'
import { processNewIngredients, type Recipe } from '../services/ingredient-id'
import { setCache, CACHE_DURATION_MS_DEFAULT } from '../services/cache'

/**
 * Transform a single recipe response, processing new ingredients
 */
async function transformRecipeResponse(response: Response): Promise<Response> {
  if (!response.ok) return response

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
}

/**
 * Transform a recipes list response (e.g., /recipes/random),
 * processing new ingredients and caching individual recipes
 */
async function transformRecipesResponse(response: Response): Promise<Response> {
  if (!response.ok) return response

  const body = await response.json()

  if (typeof body === 'object' && body != null && 'recipes' in body) {
    const recipes = body.recipes as Recipe[]
    for (const recipe of recipes) {
      // Process new ingredients (those with id=-1) - mutates in place
      if (recipe.extendedIngredients) {
        processNewIngredients(recipe.extendedIngredients)
      }

      // Cache individual recipe for later retrieval
      if (typeof recipe.id === 'number') {
        const cacheKey = `/api/1/recipes/${recipe.id}/information`
        setCache(cacheKey, JSON.stringify(recipe), CACHE_DURATION_MS_DEFAULT)
      }
    }
  }

  // Return modified response with updated ingredient IDs
  return new Response(JSON.stringify(body), {
    status: response.status,
    headers: { 'Content-Type': 'application/json' },
  })
}

export const ingredientProcessor = defineHandler({
  name: 'ingredient-processor',

  routes: {
    '/api/1/recipes/random': async (req, next) => {
      const response = await next()
      return transformRecipesResponse(response)
    },
    '/api/1/recipes/:id/information': async (req, next) => {
      // req.params.id is typed as string
      const response = await next()
      return transformRecipeResponse(response)
    },
  },
})
