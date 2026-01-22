import SwiftUI

struct FeedPostView: View {
    let post: FeedPost
    
    @State private var currentImageIndex: Int = 0
    @State private var isLiked: Bool = false
    @State private var isBookmarked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - Username only (no avatar)
            headerView
            
            // Image Carousel
            imageCarouselView
            
            // Actions Row
            actionsView
            
            // Caption and Comments
            captionView
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text(post.username)
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            Button {
                // More options action
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Image Carousel View
    
    private var imageCarouselView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(post.images.enumerated()), id: \.offset) { index, imageName in
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: UIScreen.main.bounds.width) // Square aspect ratio
            
            // Page indicator (only show if more than 1 image)
            if post.images.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<post.images.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentImageIndex ? Color.accentColor : Color.white.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Capsule().fill(Color.black.opacity(0.3)))
                .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Actions View
    
    private var actionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                // Like button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLiked.toggle()
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundStyle(isLiked ? .red : .primary)
                }
                
                // Comment button
                Button {
                    // Comment action
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 22))
                        .foregroundStyle(.primary)
                }
                
                // Share button
                Button {
                    // Share action
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 22))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Bookmark button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isBookmarked.toggle()
                    }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 22))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            
            // Likes count
            Text("\(formatNumber(post.likesCount)) likes")
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Caption View
    
    private var captionView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Username + Caption
            Text(post.username)
                .font(.system(size: 14, weight: .semibold)) +
            Text(" ") +
            Text(post.caption)
                .font(.system(size: 14))
            
            // View all comments
            if post.commentsCount > 0 {
                Button {
                    // View comments action
                } label: {
                    Text("View all \(post.commentsCount) comments")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Time ago
            Text(post.postedTimeAgo)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }
    
    // MARK: - Helpers
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return "\(number)"
    }
}

#Preview {
    ScrollView {
        FeedPostView(post: FeedPost.mockPosts[0])
    }
}
