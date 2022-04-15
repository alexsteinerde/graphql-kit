import Vapor
import Graphiti
import GraphQL

extension RoutesBuilder {
    public func register<RootType>(
        graphQLSchema schema: Schema<RootType, Request>,
        withResolver rootAPI: RootType,
        at path: PathComponent="graphql",
        postBodyStreamStrategy: HTTPBodyStreamStrategy = .collect,
        customEncoder: ContentEncoder? = nil
    ) {
        self.on(.POST, path, body: postBodyStreamStrategy) { (request) -> EventLoopFuture<Response> in
            try request.resolveByBody(
                graphQLSchema: schema,
                with: rootAPI
            ).flatMap { result in
                result.encodeResponse(
                    status: .ok,
                    for: request,
                    using: customEncoder
                )
            }
        }
        self.get(path) { (request) -> EventLoopFuture<Response> in
            try request.resolveByQueryParameters(
                graphQLSchema: schema,
                with: rootAPI
            ).flatMap { result in
                result.encodeResponse(
                    status: .ok,
                    for: request,
                    using: customEncoder
                )
            }
        }
    }
}

enum GraphQLResolveError: Swift.Error {
    case noQueryFound
}

extension GraphQLResult: Content {
    func encodeResponse(
        status: HTTPStatus,
        headers: HTTPHeaders = [:],
        for request: Request,
        using encoder: ContentEncoder?
    ) -> EventLoopFuture<Response> {
        if let encoder = encoder {
            let response = Response()
            do {
                var body = ByteBufferAllocator().buffer(capacity: 0)
                try encoder.encode(self, to: &body, headers: &response.headers)
                response.body = Response.Body(buffer: body)
                
                for (name, value) in headers {
                    response.headers.replaceOrAdd(
                        name: name,
                        value: value
                    )
                }
                
                response.status = status
            } catch {
                return request.eventLoop.makeFailedFuture(error)
            }
            return request.eventLoop.makeSucceededFuture(response)
        } else {
            return self.encodeResponse(
                status: status,
                headers: headers,
                for: request
            )
        }
    }
}

extension GraphQLJSONEncoder: ContentEncoder {
    public func encode<E>(
        _ encodable: E,
        to body: inout ByteBuffer,
        headers: inout HTTPHeaders
    ) throws where E: Encodable {
        headers.contentType = .json
        try body.writeBytes(self.encode(encodable))
    }
}
