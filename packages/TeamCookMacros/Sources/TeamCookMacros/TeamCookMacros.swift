// The Swift Programming Language
// https://docs.swift.org/swift-book

// Note: The enum MUST declare `case unsupported(String)` itself.
// The macro generates RawRepresentable and Codable conformance.
//
// Usage:
//   @SafeEnum  // defaults to case name as raw value (e.g., solid → "solid")
//   @SafeEnum(rawValues: ["solid": "SOLID", "liquid": "LIQUID"])  // explicit mapping
//   @SafeEnum(rawValueTransform: .uppercase)  // solid → "SOLID"
//   @SafeEnum(rawValueTransform: .snakeCase)  // solidItem → "solid_item"
//   @SafeEnum(rawValueTransform: .screamingSnakeCase)  // solidItem → "SOLID_ITEM"
//

/// Transformation to apply to enum case names to generate raw values
public enum RawValueTransform {
    /// Keep case name as-is (default)
    case identity
    /// Convert to UPPERCASE
    case uppercase
    /// Convert to lowercase
    case lowercase
    /// Convert camelCase to snake_case
    case snakeCase
    /// Convert camelCase to SCREAMING_SNAKE_CASE
    case screamingSnakeCase
}

@attached(member)
@attached(extension, conformances: RawRepresentable, Codable, names: named(RawValue), named(init), named(rawValue), named(encode))
public macro SafeEnum(rawValues: [String: String] = [:]) = #externalMacro(module: "TeamCookMacrosImpl", type: "SafeEnumMacro")

@attached(member)
@attached(extension, conformances: RawRepresentable, Codable, names: named(RawValue), named(init), named(rawValue), named(encode))
public macro SafeEnum(rawValueTransform: RawValueTransform) = #externalMacro(module: "TeamCookMacrosImpl", type: "SafeEnumMacro")

// MARK: - UnsafeEnum (DEPRECATED - Causes EXC_BAD_ACCESS)

/// ⚠️ DEPRECATED: This macro demonstrates a pattern that causes runtime crashes (EXC_BAD_ACCESS).
///
/// The crash occurs because Swift has issues with macro-generated enum cases that have associated values.
/// When the macro adds `case unsupported(String)` to the enum body, the memory layout becomes corrupted,
/// causing crashes during deallocation of structs containing the enum.
///
/// Use `@SafeEnum` instead, which requires the user to declare the `unsupported` case manually.
///
/// This macro is preserved as a cautionary example. DO NOT USE IN PRODUCTION.
@available(*, deprecated, message: "Causes EXC_BAD_ACCESS crashes. Use @SafeEnum instead.")
@attached(member, names: named(unsupported))
@attached(extension, conformances: RawRepresentable, Codable, names: named(RawValue), named(init), named(rawValue), named(encode))
public macro UnsafeEnum() = #externalMacro(module: "TeamCookMacrosImpl", type: "UnsafeEnumMacro")

// MARK: - BrandedID

/// Creates a branded ID type with RawRepresentable, Hashable, Codable, Sendable, and ExpressibleByIntegerLiteral conformances.
///
/// Usage:
///   @BrandedID
///   struct RecipeID {}
///
/// Expands to:
///   struct RecipeID: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByIntegerLiteral {
///       var rawValue: UInt32
///       init(rawValue: UInt32) { self.rawValue = rawValue }
///       init(integerLiteral value: UInt32) { self.init(rawValue: value) }
///   }
@attached(member, names: named(rawValue), named(init))
@attached(extension, conformances: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByIntegerLiteral, names: named(RawValue))
public macro BrandedID() = #externalMacro(module: "TeamCookMacrosImpl", type: "BrandedIDMacro")
