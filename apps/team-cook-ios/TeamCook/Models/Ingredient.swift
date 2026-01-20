import Foundation

typealias IngredientID = UInt32

struct Ingredient: Identifiable, Codable {
    var id: IngredientID
    var name: String
    var measures: IngredientMeasures
    var consistency: IngredientConsistency
}
