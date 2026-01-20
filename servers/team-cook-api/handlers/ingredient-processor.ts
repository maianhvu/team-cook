import { defineHandler } from '../handler/types'
import type { Ingredient, Recipe } from '../models/Ingredient'
import { processNewIngredients } from '../services/ingredient-id'
import { setCache, CACHE_DURATION_MS_DEFAULT } from '../services/cache'

/**
 * Dedupe ingredients by ID, keeping the first occurrence of each ID
 */
function dedupeIngredients(ingredients: Ingredient[]): Ingredient[] {
  const seen = new Set<number>()
  return ingredients.filter((ing) => {
    if (seen.has(ing.id)) {
      return false
    }
    seen.add(ing.id)
    return true
  })
}

/**
 * Process a recipe's ingredients: assign IDs to unknown ingredients, then dedupe
 */
function processRecipeIngredients(recipe: Recipe): void {
  if (!recipe.extendedIngredients) return

  // First, assign IDs to ingredients with id=-1
  processNewIngredients(recipe.extendedIngredients)

  // Then dedupe by ID, keeping first occurrence
  recipe.extendedIngredients = dedupeIngredients(recipe.extendedIngredients)
}

/**
 * Transform a single recipe response, processing new ingredients
 */
async function transformRecipeResponse(response: Response): Promise<Response> {
  if (!response.ok) return response

  const recipe = (await response.json()) as Recipe
  processRecipeIngredients(recipe)

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
      // Process ingredients: assign IDs to unknown, then dedupe
      processRecipeIngredients(recipe)

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
