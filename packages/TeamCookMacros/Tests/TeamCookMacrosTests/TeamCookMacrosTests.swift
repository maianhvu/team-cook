import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(TeamCookMacrosImpl)
import TeamCookMacrosImpl

let testMacros: [String: Macro.Type] = [
    "SafeEnum": SafeEnumMacro.self,
]
#endif

final class TeamCookMacrosTests: XCTestCase {
    
    // MARK: - Valid Usage Tests (no raw type declared)
    
    func testSafeEnumWithoutRawType() throws {
        #if canImport(TeamCookMacrosImpl)
        // User must declare unsupported(String) case themselves
        // Default raw value is same as case name
        assertMacroExpansion(
            """
            @SafeEnum
            enum IngredientConsistency {
                case solid
                case liquid
                case unsupported(String)
            }
            """,
            expandedSource: """
            enum IngredientConsistency {
                case solid
                case liquid
                case unsupported(String)
            }

            extension IngredientConsistency: RawRepresentable, Codable {
                typealias RawValue = String
                init(rawValue: String) {
                    switch rawValue {
                    case "solid":
                        self = .solid
                    case "liquid":
                        self = .liquid
                    default:
                        self = .unsupported(rawValue)
                    }
                }
                var rawValue: String {
                    switch self {
                    case .solid:
                        return "solid"
                    case .liquid:
                        return "liquid"
                    case .unsupported(let value):
                        return value
                    }
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self.init(rawValue: rawValue)
                }
                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testSafeEnumWithMultipleCases() throws {
        #if canImport(TeamCookMacrosImpl)
        assertMacroExpansion(
            """
            @SafeEnum
            enum Status {
                case active
                case inactive
                case pending
                case unsupported(String)
            }
            """,
            expandedSource: """
            enum Status {
                case active
                case inactive
                case pending
                case unsupported(String)
            }

            extension Status: RawRepresentable, Codable {
                typealias RawValue = String
                init(rawValue: String) {
                    switch rawValue {
                    case "active":
                        self = .active
                    case "inactive":
                        self = .inactive
                    case "pending":
                        self = .pending
                    default:
                        self = .unsupported(rawValue)
                    }
                }
                var rawValue: String {
                    switch self {
                    case .active:
                        return "active"
                    case .inactive:
                        return "inactive"
                    case .pending:
                        return "pending"
                    case .unsupported(let value):
                        return value
                    }
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self.init(rawValue: rawValue)
                }
                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testSafeEnumWithMultipleCasesOnSameLine() throws {
        #if canImport(TeamCookMacrosImpl)
        assertMacroExpansion(
            """
            @SafeEnum
            enum Color {
                case red, green, blue
                case unsupported(String)
            }
            """,
            expandedSource: """
            enum Color {
                case red, green, blue
                case unsupported(String)
            }

            extension Color: RawRepresentable, Codable {
                typealias RawValue = String
                init(rawValue: String) {
                    switch rawValue {
                    case "red":
                        self = .red
                    case "green":
                        self = .green
                    case "blue":
                        self = .blue
                    default:
                        self = .unsupported(rawValue)
                    }
                }
                var rawValue: String {
                    switch self {
                    case .red:
                        return "red"
                    case .green:
                        return "green"
                    case .blue:
                        return "blue"
                    case .unsupported(let value):
                        return value
                    }
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self.init(rawValue: rawValue)
                }
                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testSafeEnumWithUppercaseTransform() throws {
        #if canImport(TeamCookMacrosImpl)
        assertMacroExpansion(
            """
            @SafeEnum(rawValueTransform: .uppercase)
            enum Status {
                case active
                case pending
                case unsupported(String)
            }
            """,
            expandedSource: """
            enum Status {
                case active
                case pending
                case unsupported(String)
            }

            extension Status: RawRepresentable, Codable {
                typealias RawValue = String
                init(rawValue: String) {
                    switch rawValue {
                    case "ACTIVE":
                        self = .active
                    case "PENDING":
                        self = .pending
                    default:
                        self = .unsupported(rawValue)
                    }
                }
                var rawValue: String {
                    switch self {
                    case .active:
                        return "ACTIVE"
                    case .pending:
                        return "PENDING"
                    case .unsupported(let value):
                        return value
                    }
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self.init(rawValue: rawValue)
                }
                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testSafeEnumWithSnakeCaseTransform() throws {
        #if canImport(TeamCookMacrosImpl)
        assertMacroExpansion(
            """
            @SafeEnum(rawValueTransform: .snakeCase)
            enum UserStatus {
                case isActive
                case isPending
                case hasExpired
                case unsupported(String)
            }
            """,
            expandedSource: """
            enum UserStatus {
                case isActive
                case isPending
                case hasExpired
                case unsupported(String)
            }

            extension UserStatus: RawRepresentable, Codable {
                typealias RawValue = String
                init(rawValue: String) {
                    switch rawValue {
                    case "is_active":
                        self = .isActive
                    case "is_pending":
                        self = .isPending
                    case "has_expired":
                        self = .hasExpired
                    default:
                        self = .unsupported(rawValue)
                    }
                }
                var rawValue: String {
                    switch self {
                    case .isActive:
                        return "is_active"
                    case .isPending:
                        return "is_pending"
                    case .hasExpired:
                        return "has_expired"
                    case .unsupported(let value):
                        return value
                    }
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self.init(rawValue: rawValue)
                }
                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testSafeEnumWithScreamingSnakeCaseTransform() throws {
        #if canImport(TeamCookMacrosImpl)
        assertMacroExpansion(
            """
            @SafeEnum(rawValueTransform: .screamingSnakeCase)
            enum ErrorCode {
                case notFound
                case serverError
                case unsupported(String)
            }
            """,
            expandedSource: """
            enum ErrorCode {
                case notFound
                case serverError
                case unsupported(String)
            }

            extension ErrorCode: RawRepresentable, Codable {
                typealias RawValue = String
                init(rawValue: String) {
                    switch rawValue {
                    case "NOT_FOUND":
                        self = .notFound
                    case "SERVER_ERROR":
                        self = .serverError
                    default:
                        self = .unsupported(rawValue)
                    }
                }
                var rawValue: String {
                    switch self {
                    case .notFound:
                        return "NOT_FOUND"
                    case .serverError:
                        return "SERVER_ERROR"
                    case .unsupported(let value):
                        return value
                    }
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self.init(rawValue: rawValue)
                }
                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testSafeEnumWithExplicitRawValues() throws {
        #if canImport(TeamCookMacrosImpl)
        assertMacroExpansion(
            """
            @SafeEnum(rawValues: ["active": "ACTIVE_STATUS", "inactive": "INACTIVE_STATUS"])
            enum Status {
                case active
                case inactive
                case unsupported(String)
            }
            """,
            expandedSource: """
            enum Status {
                case active
                case inactive
                case unsupported(String)
            }

            extension Status: RawRepresentable, Codable {
                typealias RawValue = String
                init(rawValue: String) {
                    switch rawValue {
                    case "ACTIVE_STATUS":
                        self = .active
                    case "INACTIVE_STATUS":
                        self = .inactive
                    default:
                        self = .unsupported(rawValue)
                    }
                }
                var rawValue: String {
                    switch self {
                    case .active:
                        return "ACTIVE_STATUS"
                    case .inactive:
                        return "INACTIVE_STATUS"
                    case .unsupported(let value):
                        return value
                    }
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self.init(rawValue: rawValue)
                }
                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(self.rawValue)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    // MARK: - Invalid Usage Tests (raw type declared - should emit error)
    
    func testSafeEnumWithStringRawTypeEmitsError() throws {
        #if canImport(TeamCookMacrosImpl)
        let errorMessage = "@SafeEnum cannot be used with enums that declare a raw type (': String'). Remove the raw type from the enum declaration. The macro will generate RawRepresentable conformance automatically."
        assertMacroExpansion(
            """
            @SafeEnum
            enum Consistency: String {
                case solid
                case liquid
            }
            """,
            expandedSource: """
            enum Consistency: String {
                case solid
                case liquid
            }
            """,
            diagnostics: [
                // Error emitted from both MemberMacro and ExtensionMacro
                DiagnosticSpec(message: errorMessage, line: 1, column: 1),
                DiagnosticSpec(message: errorMessage, line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testSafeEnumWithIntRawTypeEmitsError() throws {
        #if canImport(TeamCookMacrosImpl)
        let errorMessage = "@SafeEnum cannot be used with enums that declare a raw type (': Int'). Remove the raw type from the enum declaration. The macro will generate RawRepresentable conformance automatically."
        assertMacroExpansion(
            """
            @SafeEnum
            enum Priority: Int {
                case low
                case high
            }
            """,
            expandedSource: """
            enum Priority: Int {
                case low
                case high
            }
            """,
            diagnostics: [
                // Error emitted from both MemberMacro and ExtensionMacro
                DiagnosticSpec(message: errorMessage, line: 1, column: 1),
                DiagnosticSpec(message: errorMessage, line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    // MARK: - Edge Cases
    
    func testSafeEnumIgnoresNonEnum() throws {
        #if canImport(TeamCookMacrosImpl)
        assertMacroExpansion(
            """
            @SafeEnum
            struct NotAnEnum {
                var value: String
            }
            """,
            expandedSource: """
            struct NotAnEnum {
                var value: String
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
