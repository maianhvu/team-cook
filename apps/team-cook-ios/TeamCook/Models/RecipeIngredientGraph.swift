import Foundation

struct RecipeIngredientGraph {
    // Adjacency lists
    private var recipesToIngredients: [RecipeID: [IngredientID: Bool]] = [:]
    private var ingredientsToRecipes: [IngredientID: [RecipeID: Bool]] = [:]
    
    mutating func connect(_ recipeID: RecipeID, to ingredientID: IngredientID) {
        recipesToIngredients[recipeID, default: [:]][ingredientID] = true
        ingredientsToRecipes[ingredientID, default: [:]][recipeID] = true
    }
}

//func buildGraph() -> RecipeIngredientGraph {
//    var graph: RecipeIngredientGraph = .init()
//    
//    let pho: RecipeID = 1000
//    
//    let onion: IngredientID = 2001
//    let beef: IngredientID = 2002
//    
//    graph.connect(pho, to: onion)
//    graph.connect(pho, to: beef)
//
//    return graph
//}
