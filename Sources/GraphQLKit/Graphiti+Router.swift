import Vapor
import Graphiti
import GraphQL

extension Router {
    public func register<RootType: FieldKeyProvider>(graphQLSchema schema: Schema<RootType, Request>, withResolver rootAPI: RootType, at path: String="graphql") {
        self.post(path) { (request) -> EventLoopFuture<Response> in
            try request.resolveByBody(graphQLSchema: schema, with: rootAPI)
                .map({ (responseContent) in
                    request.response(responseContent, as: .json)
                })
        }
        self.get(path) { (request) -> EventLoopFuture<Response> in
            try request.resolveByQueryParameters(graphQLSchema: schema, with: rootAPI)
                .map({ (responseContent) in
                request.response(responseContent, as: .json)
            })
        }
    }
}

enum GraphQLResolveError: Swift.Error {
    case noQueryFound
}
