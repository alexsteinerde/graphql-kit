@testable import GraphQLKit
import Testing
import Vapor
import VaporTesting

@Suite
struct GraphQLKitTests {
    private func withApp(_ test: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.migrations.add(CreateUser())
        app.migrations.add(CreateArticle())
        try await app.autoMigrate()
        try await test(app)
        try await app.asyncShutdown()
    }
    
    struct SomeBearerAuthenticator: AsyncBearerAuthenticator {
        struct User: Authenticatable {}
        
        func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
            // Bearer token should be equal to `token` to pass the auth
            if bearer.token == "token" {
                request.auth.login(User())
            } else {
                throw Abort(.unauthorized)
            }
        }
        
        func authenticate(request: Request) async throws {
            // Bearer token should be equal to `token` to pass the auth
            if request.headers.bearerAuthorization?.token == "token" {
                request.auth.login(User())
            } else {
                throw Abort(.unauthorized)
            }
        }
    }
    
    struct Address: Content {
        var number: Int
        var streetName: String
        var additionalStreetName: String?
        var city: String
        var postalCode: String
        var country: String
    }
    
    struct Person: Content {
        var firstName: String
        var lastName: String
        var age: UInt
        var address: Address
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
        func test(store _: Request, _: NoArguments) -> String {
            "Hello World"
        }
        
        func number(store _: Request, _: NoArguments) -> Int {
            42
        }
        
        func person(store _: Request, _: NoArguments) throws -> Person {
            return Person(
                firstName: "John",
                lastName: "Appleseed",
                age: 42,
                address: Address(
                    number: 767,
                    streetName: "Fifth Avenue",
                    city: "New York",
                    postalCode: "NY 10153",
                    country: "United States"
                )
            )
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
    
    @Test
    func postEndpoint() async throws {
        let queryRequest = QueryRequest(query: query, operationName: nil, variables: nil)
        let data = String(data: try! JSONEncoder().encode(queryRequest), encoding: .utf8)!
        
        try await withApp { app in
            app.register(graphQLSchema: schema, withResolver: Resolver())
            
            var body = ByteBufferAllocator().buffer(capacity: 0)
            body.writeString(data)
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
            headers.contentType = .json
            
            try await app.testing().test(.POST, "/graphql", headers: headers, body: body) { res in
                #expect(res.status == .ok)
                var res = res
                let expected = #"{"data":{"test":"Hello World"}}"#
                #expect(res.body.readString(length: expected.count) == expected)
            }
        }
    }
    
    @Test
    func getEndpoint() async throws {
        try await withApp { app in
            app.register(graphQLSchema: schema, withResolver: Resolver())
            try await app.testing().test(.GET, "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)") { res in
                #expect(res.status == .ok)
                var body = res.body
                let expected = #"{"data":{"test":"Hello World"}}"#
                #expect(body.readString(length: expected.count) == expected)
            }
        }
    }
    
    @Test
    func postOperationName() async throws {
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
        
        try await withApp { app in
            app.register(graphQLSchema: schema, withResolver: Resolver())
            
            var body = ByteBufferAllocator().buffer(capacity: 0)
            body.writeString(data)
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
            headers.contentType = .json
            
            try await app.testing().test(.POST, "/graphql", headers: headers, body: body) { res in
                #expect(res.status == .ok)
                var res = res
                let expected = #"{"data":{"number":42}}"#
                #expect(res.body.readString(length: expected.count) == expected)
            }
        }
    }
    
    @Test
    func protectedPostEndpoint() async throws {
        let queryRequest = QueryRequest(query: query, operationName: nil, variables: nil)
        let data = String(data: try! JSONEncoder().encode(queryRequest), encoding: .utf8)!
        
        try await withApp { app in
            let protected = app.grouped(SomeBearerAuthenticator())
            protected.register(graphQLSchema: protectedSchema, withResolver: ProtectedResolver())
            
            var body = ByteBufferAllocator().buffer(capacity: 0)
            body.writeString(data)
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
            headers.contentType = .json
            
            var protectedHeaders = headers
            protectedHeaders.replaceOrAdd(name: .authorization, value: "Bearer token")
            
            try await app.testing().test(.POST, "/graphql", headers: headers, body: body) { res in
                #expect(res.status == .unauthorized)
            }
            
            try await app.testing().test(.POST, "/graphql", headers: protectedHeaders, body: body) { res in
                #expect(res.status == .ok)
                var res = res
                let expected = #"{"data":{"test":"Hello World"}}"#
                #expect(res.body.readString(length: expected.count) == expected)
            }
        }
    }
    
    @Test
    func protectedGetEndpoint() async throws {
        try await withApp { app in
            let protected = app.grouped(SomeBearerAuthenticator())
            protected.register(graphQLSchema: protectedSchema, withResolver: ProtectedResolver())
            
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .authorization, value: "Bearer token")
            
            try await app.testing().test(.GET, "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)") { res in
                #expect(res.status == .unauthorized)
            }
            
            try await app.testing().test(.GET, "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)", headers: headers) { res in
                #expect(res.status == .ok)
                var body = res.body
                let expected = #"{"data":{"test":"Hello World"}}"#
                #expect(body.readString(length: expected.count) == expected)
            }
        }
    }
    
    @Test
    func protectedPostOperationName() async throws {
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
        
        try await withApp { app in
            let protected = app.grouped(SomeBearerAuthenticator())
            protected.register(graphQLSchema: protectedSchema, withResolver: ProtectedResolver())
            
            var body = ByteBufferAllocator().buffer(capacity: 0)
            body.writeString(data)
            
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
            headers.contentType = .json
            
            var protectedHeaders = headers
            protectedHeaders.replaceOrAdd(name: .authorization, value: "Bearer token")
            
            try await app.testing().test(.POST, "/graphql", headers: headers, body: body) { res in
                #expect(res.status == .unauthorized)
            }
            
            try await app.testing().test(.POST, "/graphql", headers: protectedHeaders, body: body) { res in
                #expect(res.status == .ok)
                var res = res
                let expected = #"{"data":{"number":42}}"#
                #expect(res.body.readString(length: expected.count) == expected)
            }
        }
    }
    
    @Test
    func fieldsOrder() async throws {
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
        
        try await withApp { app in
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
            
            try await app.testing().test(.POST, "/graphql", headers: headers1, body: body1) { res in
                #expect(res.status == .ok)
                var res = res
                let expected = #"{"data":{"person":{"firstName":"John","lastName":"Appleseed","age":42,"address":{"number":767,"streetName":"Fifth Avenue","city":"New York","postalCode":"NY 10153","country":"United States"}}}}"#
                #expect(res.body.readString(length: expected.count) == expected)
            }
            
            try await app.testing().test(.POST, "/graphql", headers: headers2, body: body2) { res in
                #expect(res.status == .ok)
                var res = res
                let expected = #"{"data":{"person":{"address":{"city":"New York","country":"United States","number":767,"postalCode":"NY 10153","streetName":"Fifth Avenue"},"age":42,"firstName":"John","lastName":"Appleseed"}}}"#
                #expect(res.body.readString(length: expected.count) == expected)
            }
        }
    }
    
    @Test
    func testEnum() async throws {
        enum TodoState: String, Codable, CaseIterable {
            case open
            case done
            case forLater
        }
        
        final class TestResolver: Sendable {
            init() {}
            func test(store _: Request, _: NoArguments) -> TodoState {
                .open
            }
        }
        
        let schema = try Schema<TestResolver, Request> {
            Enum(TodoState.self)
            Query {
                Field("test", at: TestResolver.test)
            }
        }
        
        let query = """
        query {
            test
        }
        """
        
        try await withApp { app in
            app.register(graphQLSchema: schema, withResolver: TestResolver())
            try await app.testing().test(.GET, "/graphql?query=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)") { res in
                #expect(res.status == .ok)
                var body = res.body
                let expected = #"{"data":{"test":"open"}}"#
                #expect(body.readString(length: expected.count) == expected)
            }
        }
    }
    
    @Test
    func createTestArticles() async throws {
        let user = User(username: "tester")
        
        try await withApp { app in
            try await user.save(on: app.db)
            
            let articles = [
                Article(title: "Hello", userID: user.id!),
                Article(title: "There", userID: user.id!),
            ]
            
            for article in articles {
                try await article.save(on: app.db)
            }
            
            let savedArticles = try await Article.query(on: app.db).all()
            
            #expect(savedArticles.count == 2)
            #expect(savedArticles[1].title == "There")
        }
    }
    
    @Test
    func createTestUser() async throws {
        let user = User(username: "vaporTester")
        
        try await withApp { app in
            try await user.save(on: app.db)
            
            let users = try await User.query(on: app.db).all()
            
            #expect(users.count == 1)
            #expect(users[0].username == "vaporTester")
        }
    }
    
    struct FluentResolver {
        func articles(
            _ request: Request,
            _: NoArguments
        ) async throws -> [Article] {
            try await Article.query(on: request.db).all()
        }
        
        func users(
            _ request: Request,
            _: NoArguments
        ) async throws -> [User] {
            try await User.query(on: request.db).all()
        }
    }
    
    let fluentSchema = try! Schema<FluentResolver, Request> {
        Scalar(UUID.self)
        
        Type(Article.self) {
            Field("id", at: \.id)
            Field("title", at: \.title)
            Field("user", with: \.$user)
        }
        
        Type(User.self) {
            Field("id", at: \.id)
            Field("username", at: \.username)
            Field("articles", with: \.$articles)
        }
        
        Query {
            Field("articles", at: FluentResolver.articles)
            Field("users", at: FluentResolver.users)
        }
    }
    
    @Test
    func getArticles() async throws {
        let user = User(username: "tester")
        
        let request = QueryRequest(query: """
        query {
            articles {
                title
                user {
                    username
                }
            }
        }
        """, operationName: nil, variables: nil).query
        
        let data = try! JSONEncoder().encode(request)
        var body = ByteBufferAllocator().buffer(capacity: 0)
        body.writeData(data)
        
        try await withApp { app in
            try await user.save(on: app.db)
            
            let articles = [
                Article(title: "Hello", userID: user.id!),
                Article(title: "There", userID: user.id!),
            ]
            
            for article in articles {
                try await article.save(on: app.db)
            }
            
            app.register(graphQLSchema: fluentSchema, withResolver: FluentResolver())
            
            try await app.testing().test(
                .GET,
                "/graphql?query=\(request.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
            ) { response in
                #expect(response.status == .ok)
                let expected = #"{"data":{"articles":[{"title":"Hello","user":{"username":"tester"}},{"title":"There","user":{"username":"tester"}}]}}"#
                #expect(response.body.string == expected)
            }
        }
    }
    
    @Test
    func getUsers() async throws {
        let users = [
            User(username: "tester"),
        ]
        
        let request = QueryRequest(query: """
        query {
            users {
                username
                articles {
                    title
                }
            }
        }
        """, operationName: nil, variables: nil).query
        
        let data = try! JSONEncoder().encode(request)
        var body = ByteBufferAllocator().buffer(capacity: 0)
        body.writeData(data)
        
        try await withApp { app in
            for user in users {
                try await user.save(on: app.db)
            }
            
            let articles = [
                Article(title: "Hello", userID: users[0].id!),
                Article(title: "There", userID: users[0].id!),
            ]
            
            for article in articles {
                try await article.save(on: app.db)
            }
            
            app.register(graphQLSchema: fluentSchema, withResolver: FluentResolver())
            
            try await app.testing().test(
                .GET,
                "/graphql?query=\(request.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
            ) { response in
                #expect(response.status == .ok)
                let expected = #"{"data":{"users":[{"username":"tester","articles":[{"title":"Hello"},{"title":"There"}]}]}}"#
                #expect(response.body.string == expected)
            }
        }
    }
}
