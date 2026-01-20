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
                    NavigationLink(value: recipe.id) {
                        CookRecipeListItemView(recipe: recipe)
                    }
                    .listRowSeparator(offset == 0 ? .hidden : .automatic, edges: .top)
                    .listRowSeparator(offset == recipes.count - 1 ? .hidden : .automatic, edges: .bottom)
                }
            }
            .listStyle(.inset)
            .navigationDestination(for: RecipeID.self) { recipeID in
                if let recipe = recipes.first(where: { $0.id == recipeID }) {
                    CookRecipeDetailView(recipe: recipe)
                }
            }
        }
    }
    
    @ViewBuilder
    private func failedToLoadSuggestionsView(for error: any Error) -> some View {
        VStack(alignment: .center) {
            Image(systemName: "eyes")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Failed to load recipes")
                .font(.system(size: 20))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text(error.localizedDescription)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            #if DEBUG
            Text((error as NSError).userInfo.description)
                .font(.custom("Menlo", size: 12))
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 8))
                .padding(.horizontal)
            #endif
            
            Button("Reload") {
                $suggestedRecipes.error = nil
                $suggestedRecipes.refetch()
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .frame(maxHeight: .infinity)
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
                } else if let error = $suggestedRecipes.error {
                    failedToLoadSuggestionsView(for: error)
                }
            }
            .frame(maxWidth: .infinity)
            .searchable(text: $searchQuery, prompt: "Search recipes or ingredients")
            .navigationTitle("Cook")
        } detail: {
            EmptyView()
        }
        .onAppear { $suggestedRecipes.refetch() }
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
