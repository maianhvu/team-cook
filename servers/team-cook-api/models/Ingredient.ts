export interface Measure {
  amount: number
  unitShort: string
  unitLong: string
}

export interface Ingredient {
  id: number
  name: string
  originalName: string
  consistency?: string
  measures?: {
    us?: Measure
    metric?: Measure
  }
}

export interface Recipe {
  id: number
  extendedIngredients?: Ingredient[]
}
