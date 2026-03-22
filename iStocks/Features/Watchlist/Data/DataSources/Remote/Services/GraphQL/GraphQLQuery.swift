//
//  GraphQLQuery.swift
//  iStocks
//
//  Created by Sakir Saiyed.
//

import Foundation

// MARK: - Variable Type

/// Represents a GraphQL variable value that can be encoded as JSON
enum GraphQLVariable: Encodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([GraphQLVariable])
    case stringArray([String])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let values):
            try container.encode(values)
        case .stringArray(let values):
            try container.encode(values)
        }
    }
}

// MARK: - GraphQL Query

/// Represents a GraphQL query with optional variables and operation name
struct GraphQLQuery: Encodable {
    let query: String
    let variables: [String: GraphQLVariable]?
    let operationName: String?

    init(query: String, variables: [String: GraphQLVariable]? = nil, operationName: String? = nil) {
        self.query = query
        self.variables = variables
        self.operationName = operationName
    }

    /// Encodes the query into JSON `Data` suitable for an HTTP POST body
    func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
}
