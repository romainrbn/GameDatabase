import SwiftCompilerPlugin
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct QueryableModelMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.notAStruct
        }

        // Extract all @Field properties
        let fields = structDecl.memberBlock.members.compactMap { member -> FieldInfo? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                  let type = binding.typeAnnotation?.type,
                  varDecl.attributes.contains(where: { attr in
                      attr.as(AttributeSyntax.self)?.attributeName.description == "Field"
                  }) else {
                return nil
            }

            let key = varDecl.attributes.compactMap { attr -> String? in
                guard let attribute = attr.as(AttributeSyntax.self),
                      attribute.attributeName.description == "Field",
                      let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
                      let keyArg = arguments.first(where: { $0.label?.text == "key" }),
                      let stringLiteral = keyArg.expression.as(StringLiteralExprSyntax.self),
                      let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) else {
                    return nil
                }
                return segment.content.text
            }.first

            return FieldInfo(
                propertyName: identifier.identifier.text,
                jsonKey: key ?? identifier.identifier.text,
                type: type.description
            )
        }

        // Generate CodingKeys enum
        let codingKeysEnum = generateCodingKeys(fields: fields)

        // Generate init(from decoder:)
        let decoderInit = generateDecoderInit(structName: structDecl.name.text, fields: fields)

        // Generate fieldName(for:) method
        let fieldNameMethod = generateFieldNameMethod(structName: structDecl.name.text, fields: fields)

        return [
            DeclSyntax(codingKeysEnum),
            DeclSyntax(decoderInit),
            DeclSyntax(fieldNameMethod)
        ]
    }

    private static func generateCodingKeys(fields: [FieldInfo]) -> EnumDeclSyntax {
        let cases = fields.map { field in
            "case \(field.propertyName) = \"\(field.jsonKey)\""
        }.joined(separator: "\n")

        return try! EnumDeclSyntax(
            """
            enum CodingKeys: String, CodingKey {
                \(raw: cases)
            }
            """
        )
    }

    private static func generateDecoderInit(structName: String, fields: [FieldInfo]) -> InitializerDeclSyntax {
        let initializations = fields.map { field in
            "_\(field.propertyName) = Field(key: \"\(field.jsonKey)\")"
        }.joined(separator: "\n        ")

        let decodings = fields.map { field in
            let typeWithoutOptional = field.type.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "?", with: "")
            return "_\(field.propertyName).wrappedValue = try container.decodeIfPresent(\(typeWithoutOptional).self, forKey: .\(field.propertyName))"
        }.joined(separator: "\n        ")

        return try! InitializerDeclSyntax(
            """
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                // Initialize each field with its key
                \(raw: initializations)
                
                // Decode only the fields that are present
                \(raw: decodings)
            }
            """
        )
    }

    private static func generateFieldNameMethod(structName: String, fields: [FieldInfo]) -> FunctionDeclSyntax {
        let cases = fields.map { field in
            "case \\\(structName).\(field.propertyName): return \"\(field.jsonKey)\""
        }.joined(separator: "\n        ")

        return try! FunctionDeclSyntax(
            """
            static func fieldName(for kp: PartialKeyPath<\(raw: structName)>) -> String? {
                switch kp {
                \(raw: cases)
                default: return nil
                }
            }
            """
        )
    }
}

struct FieldInfo {
    let propertyName: String
    let jsonKey: String
    let type: String
}

enum MacroError: Error {
    case notAStruct
}

@main
struct QueryPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        QueryableModelMacro.self,
    ]
}
