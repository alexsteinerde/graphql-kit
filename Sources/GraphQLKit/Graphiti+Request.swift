import Graphiti
import GraphQL
import Vapor

extension Request {
    func resolveByBody<RootType>(
        graphQLSchema schema: Schema<RootType, Request>,
        with rootAPI: RootType
    ) async throws -> GraphQLResult {
        let queryRequest = try content.decode(QueryRequest.self)

        return try await resolve(
            byQueryRequest: queryRequest,
            graphQLSchema: schema,
            with: rootAPI
        )
    }

    func resolveByQueryParameters<RootType>(
        graphQLSchema schema: Schema<RootType, Request>,
        with rootAPI: RootType
    ) async throws -> GraphQLResult {
        guard let queryString = query[String.self, at: "query"] else {
            throw GraphQLError(GraphQLResolveError.noQueryFound)
        }

        let variables = query[String.self, at: "variables"].flatMap {
            $0.data(using: .utf8).flatMap { data -> [String: Map]? in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                return try? decoder.decode([String: Map]?.self, from: data)
            }
        }

        let operationName = query[String.self, at: "operationName"]

        let data = QueryRequest(
            query: queryString,
            operationName: operationName,
            variables: variables
        )

        return try await resolve(
            byQueryRequest: data,
            graphQLSchema: schema,
            with: rootAPI
        )
    }

    private func resolve<RootType>(
        byQueryRequest data: QueryRequest,
        graphQLSchema schema: Schema<RootType, Request>,
        with rootAPI: RootType
    ) async throws -> GraphQLResult {
        nonisolated(unsafe) let schema = schema

        return try await schema.execute(
            request: data.query,
            resolver: rootAPI,
            context: self,
            variables: data.variables ?? [:],
            operationName: data.operationName
        )
    }
}
