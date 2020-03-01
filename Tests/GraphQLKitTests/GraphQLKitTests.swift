import XCTest
import Vapor
import XCTVapor
@testable import GraphQLKit

final class GraphQLKitTests: XCTestCase {
    struct Resolver: FieldKeyProvider {
        typealias FieldKey = FieldKeys

        enum FieldKeys: String {
            case test
            case number
        }
        func test(store: Request, _: NoArguments) -> String {
            "Hello World"
        }

        func number(store: Request, _: NoArguments) -> Int {
            42
        }
    }

    let schema = Schema<Resolver, Request>([
                Query([
                    Field(.test, at: Resolver.test),
                    Field(.number, at: Resolver.number)
                ])
            ])
            let query = """
                query {
                    test
                }
                """

    func testPostEndpoint() throws {
        let queryRequest = QueryRequest(query: query, operationName: nil, variables: nil)
        let data = String(data: try! JSONEncoder().encode(queryRequest), encoding: .utf8)!

        let app = Application(.testing)
        defer { app.shutdown() }

        app.register(graphQLSchema: schema, withResolver: Resolver())

        var body = ByteBufferAllocator().buffer(capacity: 0)
        body.writeString(data)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
        headers.contentType = .json

        try app.testable().test(.POST, "/graphql", headers: headers, body: body) { res in
            XCTAssertEqual(res.status, HTTPResponseStatus.ok)
            XCTAssertEqual(res.body.description, #"{"data":{"test":"Hello World"}}"#)
        }
    }

    func testGetEndpoint() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.register(graphQLSchema: schema, withResolver: Resolver())
        try app.testable().test(.GET, "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)") { res in
            XCTAssertEqual(res.status, HTTPResponseStatus.ok)
            XCTAssertEqual(res.body.description, #"{"data":{"test":"Hello World"}}"#)
        }
    }

    func testPostOperatinName() throws {
        let multiQuery = """
query World {
    test
}

query Number {
    number
}
"""
        let queryRequest = QueryRequest(query: multiQuery, operationName: "Number", variables: nil)
        let data = String(data: try! JSONEncoder().encode(queryRequest), encoding: .utf8)!

        let app = Application(.testing)
        defer { app.shutdown() }

        app.register(graphQLSchema: schema, withResolver: Resolver())

        var body = ByteBufferAllocator().buffer(capacity: 0)
        body.writeString(data)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
        headers.contentType = .json

        try app.testable().test(.POST, "/graphql", headers: headers, body: body) { res in
            XCTAssertEqual(res.status, HTTPResponseStatus.ok)
            XCTAssertEqual(res.body.description, #"{"data":{"number":42}}"#)
        }
    }

    static let allTests = [
        ("testPostEndpoint", testPostEndpoint),
        ("testGetEndpoint", testGetEndpoint),
        ("testPostOperatinName", testPostOperatinName),
    ]
}
