# GraphQLKit
[![Language](https://img.shields.io/badge/Swift-5.1-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-4-F6CBCA.svg)](http://vapor.codes)
[![build](https://github.com/alexsteinerde/graphql-kit/workflows/build/badge.svg)](https://github.com/alexsteinerde/graphql-kit/actions)


Easy setup of a GraphQL server with Vapor. It uses the GraphQL implementation of [Graphiti](https://github.com/alexsteinerde/Graphiti).

## Features
- [x] Arguments, operation name and query support
- [x] Normal access to the `Request` object as in normal Vapor request handlers
- [x] Accept JSON in the body of a POST request as the GraphQL query
- [x] POST and GET support
- [ ] Accept `application/graphql` content type requests
- [ ] Downloadable schema file
- [ ] Multi-Resolver support

## Installation
```Swift
import PackageDescription

let package = Package(
    dependencies: [
    .package(url: "https://github.com/alexsteinerde/graphql-kit.git", from: "1.0.0"),
    ],
    targets: [
    .target(name: "App", dependencies: ["GraphQLKit"]),
    ...
    ]
)
```

## Getting Started
### Define your schema
This package is setup to accept only `Request` objects as the context object for the schema. This gives the opportunity to access all functionality that Vapor provides, for example authentication, service management and database access. To see an example implementation please have a look at the [`vapor-graphql-template`](https://github.com/alexsteinerde/vapor-graphql-template) repository.
This package only provides the needed functions to register an existing GraphQL schema on a Vapor application. To define your schema please refer to the [Graphiti](https://github.com/alexsteinerde/Graphiti) documentations.
But by including this package some other helper functions are exposed:

#### Async Resolver
An `EventLoopGroup` parameter is no longer required for async resolvers as the `Request` context object already provides access to it's `EventLoopGroup` attribute `eventLoop`.

```Swift
// Instead of adding an unnecessary parameter
func getAllTodos(store: Request, arguments: NoArguments, _: EventLoopGroup) throws -> EventLoopFuture<[Todo]> {
    Todo.query(on: store).all()
}

// You don't need to provide the eventLoopGroup parameter even when resolving a future.
func getAllTodos(store: Request, arguments: NoArguments) throws -> EventLoopFuture<[Todo]> {
    Todo.query(on: store).all()
}
```

#### Enums
It automatically resolves all cases of an enum if the type conforms to `CaseIterable`. 
```swift
enum TodoState: String, CaseIterable {
    case open
    case done
    case forLater
}

Enum(TodoState.self),
```

#### `Parent` and `Children`
Vapor has the functionality to fetch an objects parent and children automatically with `Parent` and `Children` types. To integrate this into GraphQL, GraphQLKit provides extensions to the `Field` type that lets you use the parent or children property as a keypath. The fetching of those related objects is then done automatically.

> :warning: Loading related objects in GraphQL has the [**N+1** problem](https://itnext.io/what-is-the-n-1-problem-in-graphql-dd4921cb3c1a). A solution would be to build a DataLoader package for Swift. But this hasn't been done yet.

```swift
final class User {
    ...
    var userId: UUID
    var user: Parent<Post, User> {
        parent(\.userId)
    }
    ...
}
```

```swift
// Schema type: 
Field(.user, with: \.user),
```

### Register the schema on the application
In your `configure.swift` file call the `register(graphQLSchema: Schema<YourResolver, Request>, withResolver: YourResolver)` on your `Application` instance. By default this registers the GET and POST endpoints at `/graphql`. But you can also pass the optional parameter `at:` and override the default value.

```Swift
// Register the schema and it's resolver.
app.register(graphQLSchema: todoSchema, withResolver: TodoAPI())
```

## License
This project is released under the MIT license. See [LICENSE](LICENSE) for details.

## Contribution
You can contribute to this project by submitting a detailed issue or by forking this project and sending a pull request. Contributions of any kind are very welcome :)
