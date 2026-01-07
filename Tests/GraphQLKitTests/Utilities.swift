import FluentSQLiteDriver
import Vapor
import VaporTesting

final class Article: Model, Content, @unchecked Sendable {
    static let schema = "articles"
    
    @ID
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Parent(key: "user_id")
    var user: User
    
    init() {}
    
    init(
        id: UUID? = nil,
        title: String,
        userID: User.IDValue
    ) {
        self.id = id
        self.title = title
        $user.id = userID
    }
}

struct CreateArticle: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Article.schema)
            .id()
            .field("title", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .unique(on: "id")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Article.schema).delete()
    }
}

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Children(for: \.$user)
    var articles: [Article]
    
    init() {}
    
    init(
        id: UUID? = nil,
        username: String
    ) {
        self.id = id
        self.username = username
    }
}

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("username", .string, .required)
            .unique(on: "id")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
