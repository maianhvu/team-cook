import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Errors thrown by @SafeEnum macro
enum SafeEnumError: Error, CustomStringConvertible {
    case rawTypeNotAllowed(typeName: String)
    case noFallbackCase
    case multipleFallbackCases(caseNames: [String])
    case duplicateRawValues(rawValue: String, caseNames: [String])
    
    var description: String {
        switch self {
        case .rawTypeNotAllowed(let typeName):
            return "@SafeEnum cannot be used with enums that declare a raw type (': \(typeName)'). Remove the raw type from the enum declaration. The macro will generate RawRepresentable conformance automatically."
        case .noFallbackCase:
            return "@SafeEnum requires exactly one case with an associated String value (e.g., 'case unsupported(String)') to handle unrecognized raw values."
        case .multipleFallbackCases(let caseNames):
            return "@SafeEnum requires exactly one case with an associated value, but found multiple: \(caseNames.joined(separator: ", ")). Keep only one fallback case."
        case .duplicateRawValues(let rawValue, let caseNames):
            return "@SafeEnum: Multiple cases resolve to the same raw value '\(rawValue)': \(caseNames.joined(separator: ", ")). Use explicit rawValues mapping to disambiguate."
        }
    }
}

/// Transformation to apply to enum case names to generate raw values (mirrors the public enum)
enum RawValueTransform: String {
    case identity
    case uppercase
    case lowercase
    case snakeCase
    case screamingSnakeCase
    
    /// Apply the transformation to a case name
    func apply(to name: String) -> String {
        switch self {
        case .identity:
            return name
        case .uppercase:
            return name.uppercased()
        case .lowercase:
            return name.lowercased()
        case .snakeCase:
            return name.toSnakeCase()
        case .screamingSnakeCase:
            return name.toSnakeCase().uppercased()
        }
    }
}

extension String {
    /// Convert camelCase to snake_case
    func toSnakeCase() -> String {
        var result = ""
        for (index, char) in self.enumerated() {
            if char.isUppercase {
                if index > 0 {
                    result += "_"
                }
                result += char.lowercased()
            } else {
                result += String(char)
            }
        }
        return result
    }
}

public struct SafeEnumMacro: MemberMacro, ExtensionMacro {
    
    /// Known raw value types that enums can have
    private static let knownRawValueTypes: Set<String> = [
        "String", "Int", "Int8", "Int16", "Int32", "Int64",
        "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
        "Double", "Float", "Character"
    ]
    
    /// Checks if the enum declares a raw type (which is not allowed with @SafeEnum)
    private static func checkForRawType(in enumDecl: EnumDeclSyntax) -> String? {
        guard let inheritanceClause = enumDecl.inheritanceClause else {
            return nil
        }
        
        for inheritedType in inheritanceClause.inheritedTypes {
            let typeName = inheritedType.type.trimmedDescription
            if knownRawValueTypes.contains(typeName) {
                return typeName
            }
        }
        
        return nil
    }
    
    /// Represents an enum case with its name and raw value
    private struct EnumCase {
        let name: String
        let rawValue: String
    }
    
    /// Represents a case with an associated value (the fallback case)
    private struct FallbackCase {
        let name: String
    }
    
    /// Finds all cases with associated values in the enum
    /// Returns the names of cases that have associated values
    private static func findFallbackCases(in enumDecl: EnumDeclSyntax) -> [String] {
        var fallbackCases: [String] = []
        
        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            
            for element in caseDecl.elements {
                // Check if this case has associated values
                if element.parameterClause != nil {
                    fallbackCases.append(element.name.text)
                }
            }
        }
        
        return fallbackCases
    }
    
    /// Validates the enum structure and returns the fallback case name
    private static func validateAndGetFallbackCase(in enumDecl: EnumDeclSyntax) throws -> FallbackCase {
        let fallbackCases = findFallbackCases(in: enumDecl)
        
        if fallbackCases.isEmpty {
            throw SafeEnumError.noFallbackCase
        }
        
        if fallbackCases.count > 1 {
            throw SafeEnumError.multipleFallbackCases(caseNames: fallbackCases)
        }
        
        return FallbackCase(name: fallbackCases[0])
    }
    
    /// Validates that no two cases resolve to the same raw value
    private static func validateNoDuplicateRawValues(cases: [EnumCase]) throws {
        var rawValueToCases: [String: [String]] = [:]
        
        for enumCase in cases {
            // Strip quotes from raw value for comparison
            let rawValue = enumCase.rawValue.replacingOccurrences(of: "\"", with: "")
            rawValueToCases[rawValue, default: []].append(enumCase.name)
        }
        
        for (rawValue, caseNames) in rawValueToCases {
            if caseNames.count > 1 {
                throw SafeEnumError.duplicateRawValues(rawValue: rawValue, caseNames: caseNames)
            }
        }
    }
    
    /// Parses the rawValues dictionary from the macro attribute arguments
    /// e.g., @SafeEnum(rawValues: ["solid": "SOLID", "liquid": "LIQUID"])
    private static func parseRawValuesMapping(from node: AttributeSyntax) -> [String: String] {
        var mapping: [String: String] = [:]
        
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return mapping
        }
        
        for argument in arguments {
            // Look for the "rawValues" argument
            guard argument.label?.text == "rawValues",
                  let dictExpr = argument.expression.as(DictionaryExprSyntax.self) else {
                continue
            }
            
            // Parse dictionary elements
            if case .elements(let elements) = dictExpr.content {
                for element in elements {
                    // Extract key (case name)
                    guard let keyExpr = element.key.as(StringLiteralExprSyntax.self),
                          let keySegment = keyExpr.segments.first?.as(StringSegmentSyntax.self) else {
                        continue
                    }
                    let key = keySegment.content.text
                    
                    // Extract value (raw value)
                    guard let valueExpr = element.value.as(StringLiteralExprSyntax.self),
                          let valueSegment = valueExpr.segments.first?.as(StringSegmentSyntax.self) else {
                        continue
                    }
                    let value = valueSegment.content.text
                    
                    mapping[key] = value
                }
            }
        }
        
        return mapping
    }
    
    /// Parses the rawValueTransform from the macro attribute arguments
    /// e.g., @SafeEnum(rawValueTransform: .uppercase)
    private static func parseRawValueTransform(from node: AttributeSyntax) -> RawValueTransform {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return .identity
        }
        
        for argument in arguments {
            // Look for the "rawValueTransform" argument
            guard argument.label?.text == "rawValueTransform",
                  let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) else {
                continue
            }
            
            // Extract the enum case name (e.g., "uppercase" from ".uppercase")
            let transformName = memberAccess.declName.baseName.text
            if let transform = RawValueTransform(rawValue: transformName) {
                return transform
            }
        }
        
        return .identity
    }
    
    /// Extracts all cases from an enum declaration, including their raw values
    /// Priority: 1) explicit mapping, 2) transform (defaults to identity)
    /// NOTE: The fallback case (with associated value) is excluded - it's handled specially
    private static func extractCases(
        from enumDecl: EnumDeclSyntax,
        explicitRawValues: [String: String],
        transform: RawValueTransform,
        fallbackCaseName: String
    ) -> [EnumCase] {
        var cases: [EnumCase] = []
        
        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            
            for element in caseDecl.elements {
                let name = element.name.text
                
                // Skip the fallback case - it's handled specially
                if name == fallbackCaseName {
                    continue
                }
                
                let rawValue: String
                if let explicitValue = explicitRawValues[name] {
                    // Use explicit mapping from @SafeEnum(rawValues: [...])
                    rawValue = "\"\(explicitValue)\""
                } else {
                    // Apply the transform to the case name
                    let transformedName = transform.apply(to: name)
                    rawValue = "\"\(transformedName)\""
                }
                
                cases.append(EnumCase(name: name, rawValue: rawValue))
            }
        }
        
        return cases
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }
        
        // Check if the enum declares a raw type - this is NOT allowed
        if let rawTypeName = checkForRawType(in: enumDecl) {
            throw SafeEnumError.rawTypeNotAllowed(typeName: rawTypeName)
        }
        
        // Validate the fallback case exists and is unique
        _ = try validateAndGetFallbackCase(in: enumDecl)
        
        // Also validate for duplicate raw values early
        let explicitRawValues = parseRawValuesMapping(from: node)
        let transform = parseRawValueTransform(from: node)
        let fallbackCases = findFallbackCases(in: enumDecl)
        let fallbackCaseName = fallbackCases.first ?? ""
        let cases = extractCases(from: enumDecl, explicitRawValues: explicitRawValues, transform: transform, fallbackCaseName: fallbackCaseName)
        try validateNoDuplicateRawValues(cases: cases)
        
        // MemberMacro no longer adds the unsupported case - user must declare it.
        // This avoids potential Swift compiler issues with macro-generated enum cases.
        return []
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }
        
        // Check if the enum declares a raw type - this is NOT allowed
        if let rawTypeName = checkForRawType(in: enumDecl) {
            throw SafeEnumError.rawTypeNotAllowed(typeName: rawTypeName)
        }
        
        // Validate and get the fallback case (the case with associated value)
        let fallbackCase = try validateAndGetFallbackCase(in: enumDecl)
        
        let rawType: TypeSyntax = "String"
        let explicitRawValues = parseRawValuesMapping(from: node)
        let transform = parseRawValueTransform(from: node)
        let cases = extractCases(from: enumDecl, explicitRawValues: explicitRawValues, transform: transform, fallbackCaseName: fallbackCase.name)
        
        // Validate no duplicate raw values
        try validateNoDuplicateRawValues(cases: cases)
        
        // Generate switch cases for decoding (rawValue -> case)
        let decodeCases = cases.map { enumCase in
            "case \(enumCase.rawValue): self = .\(enumCase.name)"
        }.joined(separator: "\n")
        
        // Generate switch cases for encoding (case -> rawValue)
        let encodeCases = cases.map { enumCase in
            "case .\(enumCase.name): return \(enumCase.rawValue)"
        }.joined(separator: "\n")
        
        // Generate the full extension with RawRepresentable and Codable implementation
        // We generate both to avoid conflicts with auto-synthesized implementations
        let extensionDecl = try ExtensionDeclSyntax("extension \(type): RawRepresentable, Codable") {
            // typealias RawValue = String
            "typealias RawValue = \(rawType)"
            
            // init(rawValue:) - non-failable, unknown values go to the fallback case
            try InitializerDeclSyntax("init(rawValue: \(rawType))") {
                """
                switch rawValue {
                \(raw: decodeCases)
                default: self = .\(raw: fallbackCase.name)(rawValue)
                }
                """
            }
            
            // var rawValue: RawType
            try VariableDeclSyntax("var rawValue: \(rawType)") {
                """
                switch self {
                \(raw: encodeCases)
                case .\(raw: fallbackCase.name)(let value): return value
                }
                """
            }
            
            // init(from decoder:) - Codable decoding
            try InitializerDeclSyntax("init(from decoder: Decoder) throws") {
                "let container = try decoder.singleValueContainer()"
                "let rawValue = try container.decode(\(rawType).self)"
                "self.init(rawValue: rawValue)"
            }
            
            // encode(to encoder:) - Codable encoding
            try FunctionDeclSyntax("func encode(to encoder: Encoder) throws") {
                "var container = encoder.singleValueContainer()"
                "try container.encode(self.rawValue)"
            }
        }
        
        return [extensionDecl]
    }
}

// MARK: - BrandedIDMacro

/// Errors thrown by @BrandedID macro
enum BrandedIDError: Error, CustomStringConvertible {
    case notAStruct
    case structHasMembers
    
    var description: String {
        switch self {
        case .notAStruct:
            return "@BrandedID can only be applied to structs."
        case .structHasMembers:
            return "@BrandedID can only be applied to empty structs. Remove all existing members."
        }
    }
}

public struct BrandedIDMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw BrandedIDError.notAStruct
        }
        
        // Check that the struct is empty (no members)
        let members = structDecl.memberBlock.members.filter { member in
            // Filter out any existing members that aren't just whitespace/comments
            member.decl.as(VariableDeclSyntax.self) != nil ||
            member.decl.as(FunctionDeclSyntax.self) != nil ||
            member.decl.as(InitializerDeclSyntax.self) != nil
        }
        
        if !members.isEmpty {
            throw BrandedIDError.structHasMembers
        }
        
        return [
            "var rawValue: UInt32",
            """
            init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            """,
            """
            init(integerLiteral value: UInt32) {
                self.init(rawValue: value)
            }
            """
        ]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw BrandedIDError.notAStruct
        }
        
        // Check that the struct is empty (no members)
        let members = structDecl.memberBlock.members.filter { member in
            member.decl.as(VariableDeclSyntax.self) != nil ||
            member.decl.as(FunctionDeclSyntax.self) != nil ||
            member.decl.as(InitializerDeclSyntax.self) != nil
        }
        
        if !members.isEmpty {
            throw BrandedIDError.structHasMembers
        }
        
        let extensionDecl = try ExtensionDeclSyntax(
            "extension \(type): RawRepresentable, Hashable, Codable, Sendable, ExpressibleByIntegerLiteral"
        ) {
            "typealias RawValue = UInt32"
        }
        
        return [extensionDecl]
    }
}

// MARK: - UnsafeEnumMacro (DEPRECATED - Causes EXC_BAD_ACCESS)

/// ⚠️ DEPRECATED: This macro demonstrates a pattern that causes runtime crashes.
///
/// The crash occurs because Swift has issues with macro-generated enum cases that have associated values.
/// When this macro adds `case unsupported(String)` to the enum body via MemberMacro, the memory layout
/// becomes corrupted, causing EXC_BAD_ACCESS crashes during deallocation of structs containing the enum.
///
/// The fix (implemented in SafeEnumMacro) is to require users to declare the `unsupported` case manually,
/// so that all enum cases are part of the original source code rather than macro-generated.
///
/// This macro is preserved as a cautionary example. DO NOT USE IN PRODUCTION.
public struct UnsafeEnumMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else {
            return []
        }
        
        // ⚠️ THIS IS THE PROBLEMATIC PATTERN:
        // Adding an enum case with associated value via MemberMacro causes EXC_BAD_ACCESS
        let unsupportedCase = try EnumCaseDeclSyntax("case unsupported(String)")
        
        return [
            DeclSyntax(unsupportedCase)
        ]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }
        
        // Extract cases (excluding unsupported which we add via MemberMacro)
        var cases: [(name: String, rawValue: String)] = []
        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            for element in caseDecl.elements {
                let name = element.name.text
                // Use explicit raw value if declared (e.g., case solid = "SOLID"), otherwise fall back to case name
                let rawValue: String
                if let explicitValue = element.rawValue?.value {
                    rawValue = explicitValue.trimmedDescription
                } else {
                    rawValue = "\"\(name)\""
                }
                cases.append((name: name, rawValue: rawValue))
            }
        }
        
        let decodeCases = cases.map { "case \($0.rawValue): self = .\($0.name)" }.joined(separator: "\n")
        let encodeCases = cases.map { "case .\($0.name): return \($0.rawValue)" }.joined(separator: "\n")
        
        let rawType: TypeSyntax = "String"
        
        let extensionDecl = try ExtensionDeclSyntax("extension \(type): RawRepresentable, Codable") {
            "typealias RawValue = \(rawType)"
            
            try InitializerDeclSyntax("init(rawValue: \(rawType))") {
                """
                switch rawValue {
                \(raw: decodeCases)
                default: self = .unsupported(rawValue)
                }
                """
            }
            
            try VariableDeclSyntax("var rawValue: \(rawType)") {
                """
                switch self {
                \(raw: encodeCases)
                case .unsupported(let value): return value
                }
                """
            }
            
            try InitializerDeclSyntax("init(from decoder: Decoder) throws") {
                "let container = try decoder.singleValueContainer()"
                "let rawValue = try container.decode(\(rawType).self)"
                "self.init(rawValue: rawValue)"
            }
            
            try FunctionDeclSyntax("func encode(to encoder: Encoder) throws") {
                "var container = encoder.singleValueContainer()"
                "try container.encode(self.rawValue)"
            }
        }
        
        return [extensionDecl]
    }
}

@main
struct TeamCookMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SafeEnumMacro.self,
        UnsafeEnumMacro.self,
        BrandedIDMacro.self,
    ]
}
