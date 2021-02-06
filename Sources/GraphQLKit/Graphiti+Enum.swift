import Graphiti

extension Enum where EnumType: CaseIterable & Encodable & RawRepresentable {
    // Initialize an enum type from a `CaseIterable` enum.
    public convenience init(
        _ type: EnumType.Type,
        name: String? = nil
    ) {
        self.init(type) { () -> [Value<EnumType>] in
            return EnumType.allCases.map({ Value($0) })
        }
    }
}
