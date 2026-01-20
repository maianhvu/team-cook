import chalk from 'chalk'
import type { Ingredient } from '../models/Ingredient'

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

// In-memory map of ingredient names to assigned IDs (for ingredients with id=-1)
const assignedIngredientIds = new Map<string, number>()

/**
 * Get or assign a unique ID for an ingredient by name.
 * If the ingredient has been seen before, returns the same ID.
 * Otherwise, assigns a new unique ID.
 */
export function getOrAssignIngredientId(name: string, originalName: string = name): number {
  const key = `${name.toLowerCase()}|${originalName.toLowerCase()}`

  let assignedId = assignedIngredientIds.get(key)
  if (assignedId === undefined) {
    assignedId = nextIngredientId++
    assignedIngredientIds.set(key, assignedId)
    console.log(chalk.green('[INGREDIENT]'), `Assigned new ID ${assignedId} to "${name}"`)
  }

  return assignedId
}

/**
 * Process extendedIngredients to assign IDs to ingredients with id=-1
 * Deduplicates by name+originalName combination and assigns new IDs in memory
 * Mutates the ingredients array in place
 */
export function processNewIngredients(extendedIngredients: Ingredient[]): void {
  for (const ing of extendedIngredients) {
    if (ing.id !== -1) continue
    ing.id = getOrAssignIngredientId(ing.name, ing.originalName)
  }
}
