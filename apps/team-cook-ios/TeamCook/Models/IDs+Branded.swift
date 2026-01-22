import Foundation

//struct RecipeID: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByIntegerLiteral {
//    var rawValue: UInt32
//    
//    init(rawValue: UInt32) {
//        self.rawValue = rawValue
//    }
//    
//    init(integerLiteral value: UInt32) {
//        self.init(rawValue: value)
//    }
//}
//
//struct IngredientID: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByIntegerLiteral {
//    var rawValue: UInt32
//    
//    init(rawValue: UInt32) {
//        self.rawValue = rawValue
//    }
//    
//    init(integerLiteral value: UInt32) {
//        self.init(rawValue: value)
//    }
//}
//
//protocol BrandedID: RawRepresentable, Hashable, Codable, Sendable {}
//
//protocol BrandedUInt32ID: BrandedID, ExpressibleByIntegerLiteral where RawValue == UInt32, IntegerLiteralType == UInt32 {
//    init(rawValue: RawValue)
//}
//
//extension BrandedUInt32ID {
//    init(integerLiteral value: UInt32) {
//        self.init(rawValue: value)
//    }
//}

