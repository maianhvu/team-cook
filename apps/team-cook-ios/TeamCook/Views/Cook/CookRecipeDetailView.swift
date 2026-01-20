import SwiftUI

struct CookRecipeDetailView: View {
    var recipe: Recipe
    
    private let measureSystems: [IngredientMeasureSystem]
    
    @State private var selectedMeasureSystem: IngredientMeasureSystem
    
    init(recipe: Recipe) {
        self.recipe = recipe
        self.measureSystems = recipe.extendedIngredients.dropFirst()
            .reduce(into: Set(recipe.extendedIngredients.first.map { Array($0.measures.systems) } ?? [])) { measures, ingredient in
                measures.formIntersection(ingredient.measures.systems)
            }
            .sorted { $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == .orderedAscending }
        self.selectedMeasureSystem = measureSystems.first ?? .metric
    }
    
    private func title(for measureSystem: IngredientMeasureSystem) -> String {
        switch measureSystem {
        case .metric: String(localized: "Metric", comment: "Metric measurement system")
        case .us: String(localized: "US", comment: "Imperial measurement system")
        default: measureSystem.rawValue.localizedCapitalized
        }
    }
    
    private func bulletImageName(for ingredientConsistency: IngredientConsistency) -> String {
        switch ingredientConsistency {
        case .solid: return "cube"
        case .liquid: return "drop"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        AsyncImage(url: recipe.imageURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            EmptyView()
                        }
                    }
                    .clipped()
                
                VStack(alignment: .leading) {
                    Text(recipe.title)
                        .font(.system(size: 24, weight: .semibold))
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("\(Image(systemName: "carrot")) Ingredients:")
                        .font(.system(size: 20))
                    VStack(alignment: .leading) {
                        ForEach(recipe.extendedIngredients) { ingredient in
                            if let measure = ingredient.measures[selectedMeasureSystem] {
                                if measure.unitShort.isEmpty {
                                    Text("\(Image(systemName: bulletImageName(for: ingredient.consistency))) \(rounded: measure.amount, maxSignificantFigures: 1) of \(ingredient.name)")
                                } else {
                                    Text("\(Image(systemName: bulletImageName(for: ingredient.consistency))) \(rounded: measure.amount, maxSignificantFigures: 1) \(measure.unitShort) of \(ingredient.name)")
                                }
                            } else {
                                Text("\(Image(systemName: bulletImageName(for: ingredient.consistency))) \(ingredient.name)")
                            }
                        }
                        .foregroundStyle(Color(.label).opacity(0.75))
                    }
                    .padding(.leading)
                }
                .padding()
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(selection: $selectedMeasureSystem) {
                        ForEach(measureSystems, id: \.self) { system in
                            Text(title(for: system)).tag(system)
                        }
                    } label: {
                        Text("Measurements")
                    }
                } label: {
                    Button("Settings", systemImage: "gearshape") {}
                }
            }
        }
    }
}

extension LocalizedStringKey.StringInterpolation {
    fileprivate mutating func appendInterpolation(rounded number: Double, maxSignificantFigures: Int) {
        if abs(number - number.rounded()) < 1e-10 {
            appendInterpolation(Int(number))
        } else {
            appendInterpolation(String(format: "%.\(maxSignificantFigures)f", number))
        }
    }
}

#Preview {
    NavigationView {
        CookRecipeDetailView(recipe: .preview1)
    }
}
