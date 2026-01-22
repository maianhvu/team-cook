import Foundation

struct FeedPost: Identifiable {
    let id: UUID
    let username: String
    let images: [String]  // Asset image names
    let caption: String
    let recipeID: RecipeID  // Real Spoonacular recipe ID (for display only)
    let likesCount: Int
    let commentsCount: Int
    let postedTimeAgo: String
}

// MARK: - Mock Data

extension FeedPost {
    static let mockPosts: [FeedPost] = [
        FeedPost(
            id: UUID(),
            username: "homechef_maria",
            images: ["feed-carbonara-1", "feed-carbonara-2", "feed-carbonara-3"],
            caption: "Finally nailed the perfect carbonara! The secret is tempering the eggs slowly and using quality guanciale. This creamy, silky sauce coating every strand of pasta is pure comfort food heaven 🍝✨",
            recipeID: 654005,  // Orecchiette Carbonara
            likesCount: 1247,
            commentsCount: 89,
            postedTimeAgo: "2h"
        ),
        FeedPost(
            id: UUID(),
            username: "f2exican",
            images: ["feed-chives-1", "feed-chives-2"],
            caption: "Cutting a couple of chives almost every day until Apple's CEO says they're perfect.",
            recipeID: 716422,  // Caramelized Onion Dip
            likesCount: 38642,
            commentsCount: 2810,
            postedTimeAgo: "3h"
        ),
        FeedPost(
            id: UUID(),
            username: "bakingwith_james",
            images: ["feed-bread-1", "feed-bread-2"],
            caption: "Sunday baking session! There's nothing quite like the smell of fresh homemade bread filling up the kitchen. This loaf has the perfect golden crust and soft, fluffy interior 🍞",
            recipeID: 1098347,  // Homemade Banana Bread
            likesCount: 892,
            commentsCount: 56,
            postedTimeAgo: "5h"
        ),
        FeedPost(
            id: UUID(),
            username: "veggie_sarah",
            images: ["feed-avocado-1", "feed-avocado-2", "feed-avocado-3", "feed-avocado-4"],
            caption: "Brunch goals achieved! These avocado nests with perfectly poached eggs are my new obsession. Added some chili flakes and microgreens for that extra kick. Who else is team avocado? 🥑🍳",
            recipeID: 633144,  // Avocado Nests
            likesCount: 2103,
            commentsCount: 134,
            postedTimeAgo: "8h"
        ),
        FeedPost(
            id: UUID(),
            username: "grillmaster_tom",
            images: ["feed-steak-1", "feed-steak-2"],
            caption: "Weekend grilling at its finest! This chimichurri skirt steak came out absolutely perfect - beautiful char on the outside, juicy medium-rare on the inside. The homemade chimichurri sauce is a game changer 🥩🔥",
            recipeID: 638626,  // Chimichurri Skirt Steak
            likesCount: 3456,
            commentsCount: 201,
            postedTimeAgo: "1d"
        ),
        FeedPost(
            id: UUID(),
            username: "sweetooth_emma",
            images: ["feed-cake-1", "feed-cake-2", "feed-cake-3"],
            caption: "Made this decadent chocolate cake for my sister's birthday! Three layers of rich chocolate goodness with the creamiest frosting. Warning: extremely addictive! 🍫🎂",
            recipeID: 638871,  // Chocolate Cake
            likesCount: 1876,
            commentsCount: 112,
            postedTimeAgo: "2d"
        )
    ]
}
