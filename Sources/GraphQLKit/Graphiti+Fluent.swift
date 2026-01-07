import Fluent
import Graphiti
import Vapor

// Child Relationship
public extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    /// Creates a GraphQL field for a one-to-many relationship for Fluent
    /// - Parameters:
    ///   - name: Filed name
    ///   - keyPath: KeyPath to the @Children property
    convenience init<ChildType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, ChildrenProperty<ObjectType, ChildType>>
    ) where FieldType == [ChildType] {
        self.init(name.description) { type in
            { (context: Request, _: NoArguments) async throws in
                try await type[keyPath: keyPath].query(on: context.db).all() // Get the desired property and make the Fluent database query on it
            }
        }
    }
}

// Parent Relationship
public extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    /// Creates a GraphQL field for a one-to-many/one-to-one relationship for Fluent
    /// - Parameters:
    ///   - name: Field name
    ///   - keyPath: KeyPath to the @Parent property
    convenience init(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, ParentProperty<ObjectType, FieldType>>
    ) where FieldType: Model {
        self.init(name.description) { type in
            { (context: Request, _: NoArguments) async throws in
                return try await type[keyPath: keyPath].get(on: context.db)
            }
        }
    }
}

// Siblings Relationship
public extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    /// Creates a GraphQL field for a many-to-many relationship for Fluent
    /// - Parameters:
    ///   - name: Field name
    ///   - keyPath: KeyPath to the @Siblings property
    convenience init<ToType: Model, ThroughType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, SiblingsProperty<ObjectType, ToType, ThroughType>>
    ) where FieldType == [ToType] {
        self.init(name.description) { type in
            { (context: Request, _: NoArguments) async throws in
                return try await type[keyPath: keyPath].query(on: context.db).all() // Get the desired property and make the Fluent database query on it
            }
        }
    }
}

// OptionalParent Relationship
public extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    /// Creates a GraphQL field for an optional one-to-many/one-to-one relationship for Fluent
    /// - Parameters:
    ///   - name: Field name
    ///   - keyPath: KeyPath to the @OptionalParent property
    convenience init<ParentType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, OptionalParentProperty<ObjectType, ParentType>>
    ) where FieldType == ParentType? {
        self.init(name.description) { type in
            { (context: Request, _: NoArguments) async throws -> ParentType? in
                return try await type[keyPath: keyPath].get(on: context.db) // Get the desired property and make the Fluent database query on it
            }
        }
    }
}

// OptionalChild Relationship
public extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    /// Creates a GraphQL field for an optional one-to-many/one-to-one relationship for Fluent
    /// - Parameters:
    ///   - name: Field name
    ///   - keyPath: KeyPath to the @OptionalParent property
    convenience init<ParentType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, OptionalChildProperty<ObjectType, ParentType>>
    ) where FieldType == ParentType? {
        self.init(name.description) { type in
            { (context: Request, _: NoArguments) async throws -> ParentType? in
                return try await type[keyPath: keyPath].get(on: context.db)
            }
        }
    }
}
