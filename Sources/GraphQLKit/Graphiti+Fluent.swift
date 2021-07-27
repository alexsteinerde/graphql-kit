import Graphiti
import Vapor
import Fluent

// Child Relationship
extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    
    /// Creates a GraphQL field for a one-to-many  relationship for Fluent
    /// - Parameters:
    ///   - name: Filed name
    ///   - keyPath: KeyPath to the @Children property
    public convenience init<ChildType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, ChildrenProperty<ObjectType, ChildType>>
    ) where FieldType == [TypeReference<ChildType>] {
        self.init(name.description, at: { (type) -> (Request, NoArguments, EventLoopGroup) throws -> EventLoopFuture<[ChildType]> in
            return { (context: Request, arguments: NoArguments, eventLoop: EventLoopGroup) in
                return type[keyPath: keyPath].query(on: context.db).all() // Get the desired property and make the Fluent database query on it.
            }
        }, as: [TypeReference<ChildType>].self)
    }
}

// Parent Relationship
extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    
    /// Creates a GraphQL field for a one-to-many/one-to-one relationship for Fluent
    /// - Parameters:
    ///   - name: Field name
    ///   - keyPath: KeyPath to the @Parent property
    public convenience init<ParentType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, ParentProperty<ObjectType, ParentType>>
    ) where FieldType == TypeReference<ParentType> {
        self.init(name.description, at: { (type) -> (Request, NoArguments, EventLoopGroup) throws -> EventLoopFuture<ParentType> in
            return { (context: Request, arguments: NoArguments, eventLoop: EventLoopGroup) in
                return type[keyPath: keyPath].get(on: context.db)  // Get the desired property and make the Fluent database query on it.
            }
        }, as: TypeReference<ParentType>.self)
    }
}

// Siblings Relationship
extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    
    /// Creates a GraphQL field for a many-to-many relationship for Fluent
    /// - Parameters:
    ///   - name: Field name
    ///   - keyPath: KeyPath to the @Siblings property
    public convenience init<ToType: Model, ThroughType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, SiblingsProperty<ObjectType, ToType, ThroughType>>
    ) where FieldType == [TypeReference<ToType>] {
        self.init(name.description, at: { (type) -> (Request, NoArguments, EventLoopGroup) throws -> EventLoopFuture<[ToType]> in
            return { (context: Request, arguments: NoArguments, eventLoop: EventLoopGroup) in
                return type[keyPath: keyPath].query(on: context.db).all()  // Get the desired property and make the Fluent database query on it.
            }
        }, as: [TypeReference<ToType>].self)
    }
}

// OptionalParent Relationship
extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    
    /// Creates a GraphQL field for an optional one-to-many/one-to-one relationship for Fluent
    /// - Parameters:
    ///   - name: Field name
    ///   - keyPath: KeyPath to the @OptionalParent property
    public convenience init<ParentType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, OptionalParentProperty<ObjectType, ParentType>>
    ) where FieldType == TypeReference<ParentType>? {
        self.init(name.description, at: { (type) -> (Request, NoArguments, EventLoopGroup) throws -> EventLoopFuture<Optional<ParentType>> in
            return { (context: Request, arguments: NoArguments, eventLoop: EventLoopGroup) throws -> EventLoopFuture<Optional<ParentType>> in
                return type[keyPath: keyPath].get(on: context.db)  // Get the desired property and make the Fluent database query on it.
            }
        }, as: TypeReference<ParentType>?.self)
    }
}
