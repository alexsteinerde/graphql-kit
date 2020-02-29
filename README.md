# GraphQLKit
[![Language](https://img.shields.io/badge/Swift-5.1-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-3-F6CBCA.svg)](http://vapor.codes)
[![CircleCI](https://circleci.com/gh/alexsteinerde/graphql-kit.svg?style=shield)](https://circleci.com/gh/alexsteinerde/graphql-kit)


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
    .target(name: "App", dependencies: [<#T##Other Dependencies#>, "GraphQLKit"]),
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

### Register the schema on the router
In your configure.swift file call the `register(graphQLSchema: <#T##Schema<FieldKeyProvider, Request>#>, withResolver: <#T##FieldKeyProvider#>)`. By default this registers the GET and POST endpoints at `/graphql`. But you can also pass the optional parameter `at:` and override the default value.

```Swift
let router = EngineRouter.default()

// Register the schema and it's resolver.
router.register(graphQLSchema: todoSchema, withResolver: TodoAPI())

services.register(router, as: Router.self)
```

## License
This project is released under the MIT license. See [LICENSE](LICENSE) for details.

## Contribution
You can contribute to this project by submitting a detailed issue or by forking this project and sending a pull request. Contributions of any kind are very welcome :)
