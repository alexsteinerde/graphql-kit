import XCTest
import Vapor
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

        let app = try! Application.testable()
        try! app.make(Router.self).register(graphQLSchema: schema, withResolver: Resolver())
        let responder = try! app.make(Responder.self)
         // 2
        let request = HTTPRequest(method: .POST, url: URL(string: "/graphql")!, headers: HTTPHeaders([("Content-Type", "application/json")]), body: data)
         let wrappedRequest = Request(http: request, using: app)

        let response = try! responder.respond(to: wrappedRequest).wait()
        let status = response.http

        XCTAssertEqual(status.status, HTTPResponseStatus.ok)
        XCTAssertEqual(status.body.description, #"{"data":{"test":"Hello World"}}"#)
    }

    func testGetEndpoint() throws {
        let app = try! Application.testable()
        try! app.make(Router.self).register(graphQLSchema: schema, withResolver: Resolver())
        let responder = try! app.make(Responder.self)
         // 2
        let request = HTTPRequest(method: .GET, url: URL(string: "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)")!)
         let wrappedRequest = Request(http: request, using: app)

        let response = try! responder.respond(to: wrappedRequest).wait()
        let status = response.http

        XCTAssertEqual(status.status, HTTPResponseStatus.ok)
        XCTAssertEqual(status.body.description, #"{"data":{"test":"Hello World"}}"#)
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

        let app = try! Application.testable()
        try! app.make(Router.self).register(graphQLSchema: schema, withResolver: Resolver())
        let responder = try! app.make(Responder.self)
         // 2
        let request = HTTPRequest(method: .POST, url: URL(string: "/graphql")!, headers: HTTPHeaders([("Content-Type", "application/json")]), body: data)
         let wrappedRequest = Request(http: request, using: app)

        let response = try! responder.respond(to: wrappedRequest).wait()
        let status = response.http

        XCTAssertEqual(status.status, HTTPResponseStatus.ok)
        XCTAssertEqual(status.body.description, #"{"data":{"number":42}}"#)
    }

    static let allTests = [
        ("testPostEndpoint", testPostEndpoint),
        ("testGetEndpoint", testGetEndpoint),
        ("testPostOperatinName", testPostOperatinName),
    ]
}

extension Application {
  static func testable(envArgs: [String]? = nil) throws -> Application {
    let config = Config.default()
    let services = Services.default()
    var env = Environment.testing

    if let environmentArgs = envArgs {
      env.arguments = environmentArgs
    }
    let app = try Application(config: config, environment: env, services: services)


    return app
  }
}
