import Graphiti
import Vapor
import Fluent

extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    public convenience init<ChildType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, ChildrenProperty<ObjectType, ChildType>>
    ) where FieldType == [TypeReference<ChildType>] {
        self.init(name.description, at: { (type) -> (Request, NoArguments, EventLoopGroup) throws -> EventLoopFuture<[ChildType]> in
            return { (context: Request, arguments: NoArguments, eventLoop: EventLoopGroup) in
                return type[keyPath: keyPath].query(on: context.db).all()
            }
        }, as: [TypeReference<ChildType>].self)
    }
}

extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
    public convenience init<ParentType: Model>(
        _ name: FieldKey,
        with keyPath: KeyPath<ObjectType, ParentProperty<ObjectType, ParentType>>
    ) where FieldType == TypeReference<ParentType>{
        self.init(name.description, at: { (type) -> (Request, NoArguments, EventLoopGroup) throws -> EventLoopFuture<ParentType> in
            return { (context: Request, arguments: NoArguments, eventLoop: EventLoopGroup) in
                return type[keyPath: keyPath].get(on: context.db)
            }
        }, as: TypeReference<ParentType>.self)
    }
}
