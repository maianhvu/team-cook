import SwiftUI

struct FeedView: View {
    private let posts: [FeedPost] = FeedPost.mockPosts
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(posts) { post in
                    FeedPostView(post: post)
                    
                    // Divider between posts
                    if post.id != posts.last?.id {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        .navigationTitle("Feed")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        FeedView()
    }
}
