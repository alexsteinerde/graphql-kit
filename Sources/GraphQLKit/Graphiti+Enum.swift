import Graphiti

extension Enum where EnumType: CaseIterable & Encodable & RawRepresentable {
    // Initialize an enum type from a `CaseIterable` enum.
    public convenience init(
        _ type: EnumType.Type,
        as name: String? = nil
    ) {
        self.init(type, as: name) { () -> [Graphiti.Value<EnumType>] in
            return EnumType.allCases.map({ Value($0) })
        }
    }
}
