import Vapor
import Graphiti
import GraphQL


public typealias SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType> = (
    _ object: ObjectType
)  -> (
    _ context: Context,
    _ arguments: Arguments
) throws -> EventLoopFuture<ResolveType>

extension Graphiti.Field {
    convenience public init(
        name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) {
        let name = name

        let resolve: GraphQLFieldResolve = { source, arguments, context, eventLoopGroup, _ in
            guard let s = source as? ObjectType else {
                throw GraphQLError(message: "Expected source type \(ObjectType.self) but got \(type(of: source))")
            }

            guard let c = context as? Context else {
                throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
            }

            let a = try MapDecoder().decode(Arguments.self, from: arguments)

            return  try function(s)(c, a).map({ $0 })
        }

        self.init(name: name, resolve: resolve)
    }
}

extension Graphiti.Field where FieldType == ResolveType {
    public convenience init(
        _ name: FieldKey,
        with function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>
    )  {
        self.init(name: name.rawValue, at: function)
    }
}

extension Graphiti.Field where Arguments == NoArguments {
    public convenience init(
        _ name: FieldKey,
        with function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        overridingType: FieldType.Type = FieldType.self
    )  {
        self.init(name: name.rawValue, at: function)
    }
}
