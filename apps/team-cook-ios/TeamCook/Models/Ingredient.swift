import Foundation

typealias IngredientID = UInt32

struct Ingredient: Identifiable, Codable {
    var id: IngredientID
    var name: String
    var measures: IngredientMeasures
    var consistency: IngredientConsistency
}

enum IngredientConsistency: String, Codable {
    case solid = "SOLID"
    case liquid = "LIQUID"
}

struct IngredientMeasures: Codable {
    var us: IngredientMeasure
    var metric: IngredientMeasure
}

struct IngredientMeasure: Codable {
    var amount: Double
    var unitShort: String
    var unitLong: String
}
