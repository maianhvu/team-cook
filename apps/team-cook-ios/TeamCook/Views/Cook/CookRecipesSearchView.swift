import SwiftUI

struct CookRecipesSearchView: View {
    @State private var searchQuery: String = ""
    @Query(.randomRecipes(count: 10), keyPath: \.recipes) private var suggestedRecipes
    @Environment(\.networkClient) private var networkClient
    
    private struct QuerySuggestion: Identifiable {
        let id: String
        let title: LocalizedStringResource
        let emojiIcon: Character
    }
    
    private let querySuggestions: [QuerySuggestion] = [
        .init(id: "chicken-parmesan", title: "Chicken parmesan", emojiIcon: "🍗"),
        .init(id: "lettuce", title: "Lettuce", emojiIcon: "🥬"),
        .init(id: "onion", title: "Onion", emojiIcon: "🧅"),
        .init(id: "beef-pho", title: "Beef pho", emojiIcon: "🍲"),
        .init(id: "ribeye-steak", title: "Ribeye steak", emojiIcon: "🥩"),
        .init(id: "caesar-salad", title: "Caesar salad", emojiIcon: "🥗"),
    ]
    
    @ViewBuilder
    private func loadingSuggestionsView() -> some View {
        VStack {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.extraLarge)
            Text("Loading suggestions...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func suggestedRecipesList(for recipes: [Recipe]) -> some View {
        Group {
            Text("Or try something new today")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.top, 20)
            
            List {
                ForEach(recipes.enumerated(), id: \.element.id) { offset, recipe in
                    CookRecipeListItemView(recipe: recipe)
                        .listRowSeparator(offset == 0 ? .hidden : .automatic, edges: .top)
                        .listRowSeparator(offset == recipes.count - 1 ? .hidden : .automatic, edges: .bottom)
                }
            }
            .listStyle(.inset)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading) {
                FlowLayout {
                    ForEach(querySuggestions) { suggestion in
                        SearchSuggestionView(suggestion: suggestion.title, emojiIcon: suggestion.emojiIcon) {
                            var phraseResource: LocalizedStringResource = "\(suggestion.title), "
                            phraseResource.locale = .current
                            searchQuery += String(localized: phraseResource)
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                
                if let suggestedRecipes {
                    suggestedRecipesList(for: suggestedRecipes)
                } else if $suggestedRecipes.isFetching {
                    loadingSuggestionsView()
                } else {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .searchable(text: $searchQuery, prompt: "Search recipes or ingredients")
            .navigationTitle("Cook")
        } detail: {
            EmptyView()
        }
    }
}

private struct SearchSuggestionView<Icon: View>: View {
    var suggestion: LocalizedStringResource
    var icon: Icon
    var action: (() -> Void)?
    
    init(suggestion: LocalizedStringResource, @ViewBuilder icon: () -> Icon, action: (() -> Void)? = nil) {
        self.suggestion = suggestion
        self.icon = icon()
        self.action = action
    }
    
    init(suggestion: LocalizedStringResource, systemIcon: String, action: (() -> Void)? = nil) where Icon == Image {
        self.init(suggestion: suggestion, icon: { Image(systemName: systemIcon) }, action: action)
    }
    
    init(suggestion: LocalizedStringResource, emojiIcon: Character, action: (() -> Void)? = nil) where Icon == Text {
        self.init(suggestion: suggestion, icon: { Text(String(emojiIcon)) }, action: action)
    }
    
    var body: some View {
        Button { action?() } label: {
            HStack {
                icon
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(suggestion)
                    .font(.footnote)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background { RoundedRectangle(cornerRadius: 16).fill(.clear).stroke(Color(.opaqueSeparator)) }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TabView {
        Tab("Cook", systemImage: "frying.pan") {
            CookRecipesSearchView()
        }
    }
}
