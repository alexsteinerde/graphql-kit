import GraphQL

struct QueryRequest: Codable {
    var query: String
    var operationName: String?
    var variables: [String: Map]?
}
