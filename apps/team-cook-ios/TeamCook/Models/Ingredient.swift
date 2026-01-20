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

struct IngredientMeasureSystem: RawRepresentable, Hashable, CodingKey {
    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    init(stringValue: String) {
        rawValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
    
    var stringValue: String { rawValue }
    var intValue: Int? { nil }
    
    static let us = IngredientMeasureSystem(rawValue: "us")
    static let metric = IngredientMeasureSystem(rawValue: "metric")
}

struct IngredientMeasures: Codable {
    private var values: [IngredientMeasureSystem: IngredientMeasure]
    
    var systems: [IngredientMeasureSystem: IngredientMeasure].Keys { values.keys }
    
    subscript(system: IngredientMeasureSystem) -> IngredientMeasure? {
        get { values[system] }
        mutating set { values[system] = newValue }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: IngredientMeasureSystem.self)
        var values: [IngredientMeasureSystem: IngredientMeasure] = [:]
        for key in container.allKeys {
            values[key] = try container.decode(IngredientMeasure.self, forKey: key)
        }
        self.values = values
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: IngredientMeasureSystem.self)
        for (key, value) in values {
            try container.encode(value, forKey: key)
        }
    }
}

struct IngredientMeasure: Codable {
    var amount: Double
    var unitShort: String
    var unitLong: String
}
