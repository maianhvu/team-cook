import { defineHandler } from '../handler/types'
import type { Ingredient, Recipe } from '../models/Ingredient'
import { getOrAssignIngredientId } from '../services/ingredient-id'

/**
 * Create the secret ingredient with a unique ID
 */
function createLoveIngredient(): Ingredient {
  return {
    id: getOrAssignIngredientId('a lot of love'),
    name: 'a lot of love',
    originalName: 'a lot of love',
    measures: {},
    consistency: 'IMMATERIAL',
  }
}

/**
 * Inject the secret ingredient into a recipe's extendedIngredients
 */
function injectLove(recipe: Recipe): void {
  if (!recipe.extendedIngredients) {
    recipe.extendedIngredients = []
  }
  recipe.extendedIngredients.push(createLoveIngredient())
}

/**
 * Transform a single recipe response, adding the secret ingredient
 */
async function transformRecipeResponse(response: Response): Promise<Response> {
  if (!response.ok) return response

  const recipe = (await response.json()) as Recipe
  injectLove(recipe)

  return new Response(JSON.stringify(recipe), {
    status: response.status,
    headers: { 'Content-Type': 'application/json' },
  })
}

/**
 * Transform a recipes list response, adding the secret ingredient to each
 */
async function transformRecipesResponse(response: Response): Promise<Response> {
  if (!response.ok) return response

  const body = await response.json()

  if (typeof body === 'object' && body != null && 'recipes' in body) {
    const recipes = body.recipes as Recipe[]
    for (const recipe of recipes) {
      injectLove(recipe)
    }
  }

  return new Response(JSON.stringify(body), {
    status: response.status,
    headers: { 'Content-Type': 'application/json' },
  })
}

/**
 * Handler that injects the secret ingredient into every recipe response.
 * This is ephemeral - the ingredient exists only in the response body
 * and is not preserved in the cache.
 */
export const addLoveIngredient = defineHandler({
  name: 'add-love-ingredient',

  routes: {
    '/api/1/recipes/random': async (req, next) => {
      const response = await next()
      return transformRecipesResponse(response)
    },
    '/api/1/recipes/:id/information': async (req, next) => {
      const response = await next()
      return transformRecipeResponse(response)
    },
  },
})
