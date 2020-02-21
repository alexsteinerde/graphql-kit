import Graphiti
import Vapor

extension Enum where EnumType: CaseIterable {
    // Initialize an enum type from a `CaseIterable` enum.
    public convenience init(
        _ type: EnumType.Type,
        name: String? = nil
    ) {
        self.init(type, name: name, EnumType.allCases.map({ Value($0) }))
    }
}

