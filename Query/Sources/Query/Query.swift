@attached(member, names: named(init(from:)), named(CodingKeys), named(fieldName(for:)))
public macro QueryableModel() = #externalMacro(
    module: "QueryMacros",
    type: "QueryableModelMacro"
)
