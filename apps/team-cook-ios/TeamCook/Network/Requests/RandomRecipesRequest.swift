import Foundation

struct RandomRecipesRequest: NetworkRequest {
    typealias RequestBody = EmptyNetworkBody
    
    let endpoint: HTTPEndpoint = "/api/1/recipes/random"
    
    var includeNutrition: Bool?
    var includeTags: [String]?
    var excludeTags: [String]?
    var count: Int?
    
    var query: URLQuery? {
        var query = URLQuery()
        query[bool: "includeNutrition"] = includeNutrition
        query[commaSeparatedStrings: "include-tags"] = includeTags
        query[commaSeparatedStrings: "exclude-tags"] = excludeTags
        query[int: "number"] = count
        return query.isEmpty ? nil : query
    }
}

extension RandomRecipesRequest {
    struct ResponseBody: JSONResponseBody {
        var recipes: [Recipe]
    }
}

extension NetworkRequest where Self == RandomRecipesRequest {
    static func randomRecipes(includeNutrition: Bool? = nil, includeTags: [String]? = nil, excludeTags: [String]? = nil, count: Int? = nil) -> Self {
        .init(includeNutrition: includeNutrition, includeTags: includeTags, excludeTags: excludeTags, count: count)
    }
}
