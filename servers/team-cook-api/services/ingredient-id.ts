import chalk from 'chalk'

// Types for ingredient processing
export interface Measure {
  amount: number
  unitShort: string
  unitLong: string
}

export interface Ingredient {
  id: number
  name: string
  originalName: string
  measures?: {
    us?: Measure
    metric?: Measure
  }
}

export interface Recipe {
  id: number
  extendedIngredients?: Ingredient[]
}

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
 * Process extendedIngredients to assign IDs to ingredients with id=-1
 * Deduplicates by name+originalName combination and assigns new IDs in memory
 * Mutates the ingredients array in place
 */
export function processNewIngredients(extendedIngredients: Ingredient[]): void {
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
