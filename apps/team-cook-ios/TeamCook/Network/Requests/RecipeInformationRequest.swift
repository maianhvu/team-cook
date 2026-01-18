import Foundation

struct RecipeInformationRequest: NetworkRequest {
    typealias ResponseBody = Recipe
    
    var endpoint: HTTPEndpoint { .relative(path: "/api/1/recipes/\(recipeID)/information") }
    
    var recipeID: RecipeID
    var includeNutrition: Bool?
    var addWinePairing: Bool?
    var addTasteData: Bool?
    
    var query: URLQuery? {
        var query = URLQuery()
        query[bool: "includeNutrition"] = includeNutrition
        query[bool: "addWinePairing"] = addWinePairing
        query[bool: "addTasteData"] = addTasteData
        return query.isEmpty ? nil : query
    }
}

extension Recipe: JSONResponseBody {}

extension NetworkRequest where Self == RecipeInformationRequest {
    static func recipeInformation(
        for recipeID: RecipeID,
        includeNutrition: Bool? = nil,
        addWinePairing: Bool? = nil,
        addTasteData: Bool? = nil
    ) -> Self { 
        .init(
            recipeID: recipeID,
            includeNutrition: includeNutrition,
            addWinePairing: addWinePairing,
            addTasteData: addTasteData
        ) 
    }
}
