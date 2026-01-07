import Graphiti
import GraphQL
import Vapor

public extension RoutesBuilder {
    func register<RootType>(
        graphQLSchema schema: Schema<RootType, Request>,
        withResolver rootAPI: RootType,
        at path: PathComponent = "graphql",
        postBodyStreamStrategy: HTTPBodyStreamStrategy = .collect
    ) {
        nonisolated(unsafe) let schema = schema

        on(.POST, path, body: postBodyStreamStrategy) { request async throws -> Response in
            try await request.resolveByBody(graphQLSchema: schema, with: rootAPI)
                .encodeResponse(status: .ok, for: request)
        }
        get(path) { request async throws -> Response in
            try await request.resolveByQueryParameters(graphQLSchema: schema, with: rootAPI)
                .encodeResponse(status: .ok, for: request)
        }
    }
}

enum GraphQLResolveError: Swift.Error {
    case noQueryFound
}

extension GraphQLResult: @retroactive Content {
    public func encodeResponse(for _: Request) throws -> Response {
        try Response(
            status: .ok,
            headers: [
                "Content-Type": "application/json",
            ],
            body: .init(data: GraphQLJSONEncoder().encode(self))
        )
    }
}
