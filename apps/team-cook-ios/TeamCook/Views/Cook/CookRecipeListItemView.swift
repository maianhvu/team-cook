import SwiftUI

struct CookRecipeListItemView: View {
    var recipe: Recipe
    var action: (() -> Void)?
    
    var body: some View {
        Button { action?() } label: {
            HStack(alignment: .top) {
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .frame(width: 80, height: 80)
                        .overlay {
                            AsyncImage(url: recipe.imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                EmptyView()
                            }
                        }
                        .clipShape(.rect(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.system(size: 16, weight: .semibold))
                    Text("\(Image(systemName: "clock")) \(recipe.readyInMinutes) mins")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    FlowLayout {
                        if recipe.isVegetarian {
                            RecipeAttributeView(title: "Vegetarian", systemIcon: "leaf.fill", color: .green)
                        }
                        if recipe.isGlutenFree {
                            RecipeAttributeView(title: "Gluten-free", iconName: "laurel.trailing.slash", color: .orange)
                        }
                        if recipe.isVeryHealthy {
                            RecipeAttributeView(title: "Healthy", systemIcon: "heart.badge.bolt.fill", color: .red)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct RecipeAttributeView<Icon: View>: View {
    let title: String
    let icon: Icon
    let color: Color
    
    init(title: String, @ViewBuilder icon: () -> Icon, color: Color) {
        self.title = title
        self.icon = icon()
        self.color = color
    }
    
    init(title: String, systemIcon: String, color: Color) where Icon == Image {
        self.init(
            title: title,
            icon: { Image(systemName: systemIcon) },
            color: color
        )
    }
    
    init(title: String, iconName: String, color: Color) where Icon == Image {
        self.init(
            title: title,
            icon: { Image(iconName) },
            color: color
        )
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            icon
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 12))
        }
    }
}

#Preview {
    List {
        CookRecipeListItemView(recipe: .preview1)
        CookRecipeListItemView(recipe: .preview2)
    }
    .listStyle(.inset)
    .padding()
}
