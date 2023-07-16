import XCTest
import Vapor
import XCTVapor
@testable import GraphQLKit

final class GraphQLKitTests: XCTestCase {
    struct SomeBearerAuthenticator: BearerAuthenticator {
        struct User: Authenticatable {}
        
        func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<()> {
            // Bearer token should be equal to `token` to pass the auth
            if bearer.token == "token" {
                request.auth.login(User())
                return request.eventLoop.makeSucceededFuture(())
            } else {
                return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }
        }
        
        func authenticate(request: Request) -> EventLoopFuture<()> {
            // Bearer token should be equal to `token` to pass the auth
            if request.headers.bearerAuthorization?.token == "token" {
                request.auth.login(User())
                return request.eventLoop.makeSucceededFuture(())
            } else {
                return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }
        }
    }
    
    struct Address: Content {
        public var number: Int
        public var streetName: String
        public var additionalStreetName: String?
        public var city: String
        public var postalCode: String
        public var country: String
    }
    
    struct Person: Content {
        public var firstName: String
        public var lastName: String
        public var age: UInt
        public var address: Address
    }
    
    struct ProtectedResolver {
        func test(store: Request, _: NoArguments) throws -> String {
            _ = try store.auth.require(SomeBearerAuthenticator.User.self)
            return "Hello World"
        }

        func number(store: Request, _: NoArguments) throws -> Int {
            _ = try store.auth.require(SomeBearerAuthenticator.User.self)
            return 42
        }
    }
    
    struct Resolver {
        func test(store: Request, _: NoArguments) -> String {
            "Hello World"
        }

        func number(store: Request, _: NoArguments) -> Int {
            42
        }
        
        func person(store: Request, _: NoArguments) throws -> Person {
            return Person(firstName: "John", lastName: "Appleseed", age: 42, address: Address(
                number: 767,
                streetName: "Fifth Avenue",
                city: "New York",
                postalCode: "NY 10153",
                country: "United States"
            ))
        }
    }
    
    let protectedSchema = try! Schema<ProtectedResolver, Request> {
        Query {
            Field("test", at: ProtectedResolver.test)
            Field("number", at: ProtectedResolver.number)
        }
    }

    let schema = try! Schema<Resolver, Request> {
        Scalar(UInt.self)
        
        Type(Address.self) {
            Field("additionalStreetName", at: \Address.additionalStreetName)
            Field("city", at: \Address.city)
            Field("country", at: \Address.country)
            Field("number", at: \Address.number)
            Field("postalCode", at: \Address.postalCode)
            Field("streetName", at: \Address.streetName)
        }
        
        Type(Person.self) {
            Field("address", at: \Person.address)
            Field("age", at: \Person.age)
            Field("firstName", at: \Person.firstName)
            Field("lastName", at: \Person.lastName)
        }
        
        Query {
            Field("test", at: Resolver.test)
            Field("number", at: Resolver.number)
            Field("person", at: Resolver.person)
        }
    }
    
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
            XCTAssertEqual(res.status, .ok)
            var res = res
            let expected = #"{"data":{"test":"Hello World"}}"#
            XCTAssertEqual(res.body.readString(length: expected.count), expected)
        }
    }

    func testGetEndpoint() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.register(graphQLSchema: schema, withResolver: Resolver())
        try app.testable().test(.GET, "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)") { res in
            XCTAssertEqual(res.status, .ok)
            var body = res.body
            let expected = #"{"data":{"test":"Hello World"}}"#
            XCTAssertEqual(body.readString(length: expected.count), expected)
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
            XCTAssertEqual(res.status, .ok)
            var res = res
            let expected = #"{"data":{"number":42}}"#
            XCTAssertEqual(res.body.readString(length: expected.count), expected)
        }
    }
    
    func testProtectedPostEndpoint() throws {
        let queryRequest = QueryRequest(query: query, operationName: nil, variables: nil)
        let data = String(data: try! JSONEncoder().encode(queryRequest), encoding: .utf8)!

        let app = Application(.testing)
        defer { app.shutdown() }

        let protected = app.grouped(SomeBearerAuthenticator())
        protected.register(graphQLSchema: protectedSchema, withResolver: ProtectedResolver())

        var body = ByteBufferAllocator().buffer(capacity: 0)
        body.writeString(data)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
        headers.contentType = .json
        
        var protectedHeaders = headers
        protectedHeaders.replaceOrAdd(name: .authorization, value: "Bearer token")
        
        try app.testable().test(.POST, "/graphql", headers: headers, body: body) { res in
            XCTAssertEqual(res.status, .unauthorized)
        }
        
        try app.testable().test(.POST, "/graphql", headers: protectedHeaders, body: body) { res in
            XCTAssertEqual(res.status, .ok)
            var res = res
            let expected = #"{"data":{"test":"Hello World"}}"#
            XCTAssertEqual(res.body.readString(length: expected.count), expected)
        }
    }
    
    func testProtectedGetEndpoint() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        let protected = app.grouped(SomeBearerAuthenticator())
        protected.register(graphQLSchema: protectedSchema, withResolver: ProtectedResolver())
        
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .authorization, value: "Bearer token")
        
        try app.testable().test(.GET, "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)") { res in
            XCTAssertEqual(res.status, .unauthorized)
        }
        
        try app.testable().test(.GET, "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
            var body = res.body
            let expected = #"{"data":{"test":"Hello World"}}"#
            XCTAssertEqual(body.readString(length: expected.count), expected)
        }
    }
    
    func testProtectedPostOperatinName() throws {
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

        let protected = app.grouped(SomeBearerAuthenticator())
        protected.register(graphQLSchema: protectedSchema, withResolver: ProtectedResolver())

        var body = ByteBufferAllocator().buffer(capacity: 0)
        body.writeString(data)
        
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
        headers.contentType = .json
        
        var protectedHeaders = headers
        protectedHeaders.replaceOrAdd(name: .authorization, value: "Bearer token")
        
        try app.testable().test(.POST, "/graphql", headers: headers, body: body) { res in
            XCTAssertEqual(res.status, .unauthorized)
        }

        try app.testable().test(.POST, "/graphql", headers: protectedHeaders, body: body) { res in
            XCTAssertEqual(res.status, .ok)
            var res = res
            let expected = #"{"data":{"number":42}}"#
            XCTAssertEqual(res.body.readString(length: expected.count), expected)
        }
    }
    
    func testFieldsOrder() throws {
        let query1Request = QueryRequest(query: // this query returns fields in arbitrary order
                                        """
                                        query {
                                            person {
                                                firstName
                                                lastName
                                                age
                                                address {
                                                    number
                                                    streetName
                                                    city
                                                    postalCode
                                                    country
                                                }
                                            }
                                        }
                                        """, operationName: nil, variables: nil)
        let query2Request = QueryRequest(query: // this query will return all fields in alphabetical order
                                        """
                                        query {
                                            person {
                                                address {
                                                    city
                                                    country
                                                    number
                                                    postalCode
                                                    streetName
                                                }
                                                age
                                                firstName
                                                lastName
                                            }
                                        }
                                        """, operationName: nil, variables: nil)
        let data1 = String(data: try! JSONEncoder().encode(query1Request), encoding: .utf8)!
        let data2 = String(data: try! JSONEncoder().encode(query2Request), encoding: .utf8)!

        let app = Application(.testing)
        defer { app.shutdown() }

        app.register(graphQLSchema: schema, withResolver: Resolver())
        
        var body1 = ByteBufferAllocator().buffer(capacity: 0)
        body1.writeString(data1)
        var headers1 = HTTPHeaders()
        headers1.replaceOrAdd(name: .contentLength, value: body1.readableBytes.description)
        headers1.contentType = .json
        
        var body2 = ByteBufferAllocator().buffer(capacity: 0)
        body2.writeString(data2)
        var headers2 = HTTPHeaders()
        headers2.replaceOrAdd(name: .contentLength, value: body2.readableBytes.description)
        headers2.contentType = .json
        
        try app.testable().test(.POST, "/graphql", headers: headers1, body: body1) { res in
            XCTAssertEqual(res.status, .ok)
            var res = res
            let expected = #"{"data":{"person":{"firstName":"John","lastName":"Appleseed","age":42,"address":{"number":767,"streetName":"Fifth Avenue","city":"New York","postalCode":"NY 10153","country":"United States"}}}}"#
            XCTAssertEqual(res.body.readString(length: expected.count), expected)
        }
        
        try app.testable().test(.POST, "/graphql", headers: headers2, body: body2) { res in
            XCTAssertEqual(res.status, .ok)
            var res = res
            let expected = #"{"data":{"person":{"address":{"city":"New York","country":"United States","number":767,"postalCode":"NY 10153","streetName":"Fifth Avenue"},"age":42,"firstName":"John","lastName":"Appleseed"}}}"#
            XCTAssertEqual(res.body.readString(length: expected.count), expected)
        }
    }
}
