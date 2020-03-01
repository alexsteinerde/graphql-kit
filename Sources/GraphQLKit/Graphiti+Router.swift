import Vapor
import Graphiti
import GraphQL

extension Application {
    public func register<RootType: FieldKeyProvider>(graphQLSchema schema: Schema<RootType, Request>, withResolver rootAPI: RootType, at path: PathComponent="graphql") {
        self.post(path) { (request) -> EventLoopFuture<Response> in
            try request.resolveByBody(graphQLSchema: schema, with: rootAPI)
                .map({ (responseContent) in
                    Response(body: responseContent, mediaType: .json)
                })
        }
        self.get(path) { (request) -> EventLoopFuture<Response> in
            try request.resolveByQueryParameters(graphQLSchema: schema, with: rootAPI)
                .map({ (responseContent) in
                Response(body: responseContent, mediaType: .json)
            })
        }
    }
}

enum GraphQLResolveError: Swift.Error {
    case noQueryFound
}

extension Response {
    convenience init(body: String, mediaType: HTTPMediaType) {
        self.init(status: .ok, headers: HTTPHeaders.init([(HTTPHeaders.Name.contentType.description, mediaType.description)]), body: Response.Body(string: body))
    }
}
