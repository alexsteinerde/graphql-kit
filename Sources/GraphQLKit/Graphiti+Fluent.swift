//import Graphiti
//import Vapor
//import Fluent
//
//extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model {
//    public convenience init<ChildType: Model>(
//        _ name: FieldKey,
//        with keyPath: KeyPath<ObjectType, Children<ObjectType, ChildType>>
//    ) where ChildType.Database == ObjectType.Database, ResolveType == [ChildType], FieldType == [TypeReference<ChildType>] {
//
//
//        let function: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
//            return { context, arguments, eventLoop in
//                return try type[keyPath: keyPath].query(on: context).all()
//            }
//        }
//
//        self.init(name, at: function, overridingType: FieldType.self)
//    }
//}
//
//extension Graphiti.Field where Arguments == NoArguments, Context == Request, ObjectType: Model, ResolveType: Model, ObjectType.Database == ResolveType.Database, FieldType == TypeReference<ResolveType> {
//    public convenience init(
//        _ name: FieldKey,
//        with keyPath: KeyPath<ObjectType, Parent<ObjectType, ResolveType>>
//    ) {
//
//        let function: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
//            return { context, arguments, eventLoop in
//                return type[keyPath: keyPath].get(on: context)
//            }
//        }
//
//        self.init(name, at: function)
//    }
//}
