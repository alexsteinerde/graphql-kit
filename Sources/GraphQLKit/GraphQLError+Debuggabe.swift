import GraphQL
import Vapor

extension GraphQLError: Debuggable {
    public var identifier: String {
        "GraphQLError"
    }

    public var reason: String {
        message
    }
}
