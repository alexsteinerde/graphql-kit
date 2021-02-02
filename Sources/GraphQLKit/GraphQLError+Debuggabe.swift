import GraphQL
import Vapor

extension GraphQLError: AbortError {
    public var status: HTTPResponseStatus {
        return .ok
    }

    public var identifier: String {
        "GraphQLError"
    }

    public var reason: String {
        message
    }
}
