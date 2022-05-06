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
        on(.POST, path, body: postBodyStreamStrategy) { request -> EventLoopFuture<Response> in
            try request.resolveByBody(graphQLSchema: schema, with: rootAPI)
                .flatMap { $0.encodeResponse(status: .ok, for: request) }
        }
        get(path) { request -> EventLoopFuture<Response> in
            try request.resolveByQueryParameters(graphQLSchema: schema, with: rootAPI)
                .flatMap { $0.encodeResponse(status: .ok, for: request) }
        }
    }

    func register<RootType>(
        graphQLSchema schema: Schema<RootType, Request>,
        withResolver rootAPI: RootType,
        at path: PathComponent...,
        postBodyStreamStrategy: HTTPBodyStreamStrategy = .collect
    ) {
        on(.POST, path, body: postBodyStreamStrategy) { request -> EventLoopFuture<Response> in
            try request.resolveByBody(graphQLSchema: schema, with: rootAPI)
                .flatMap { $0.encodeResponse(status: .ok, for: request) }
        }
        get(path) { request -> EventLoopFuture<Response> in
            try request.resolveByQueryParameters(graphQLSchema: schema, with: rootAPI)
                .flatMap { $0.encodeResponse(status: .ok, for: request) }
        }
    }
}

enum GraphQLResolveError: Swift.Error {
    case noQueryFound
}

extension GraphQLResult: Content {}
