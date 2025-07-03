//
//  TwelveDataAPIError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.
//

import Foundation

enum TwelveDataAPIError: LocalizedError, Decodable {
    case badRequest(message: String)
    case unauthorized
    case forbidden
    case notFound(message: String)
    case parameterTooLong
    case tooManyRequests
    case internalServerError
    case unknownError(code: Int, message: String)
    case invalidResponse(statusCode: Int, body: String)
    case invalidSymbols([String])

    // Description shown in UI or logs
    var errorDescription: String? {
        switch self {
        case .badRequest(let msg): return "Bad Request: \(msg)"
        case .unauthorized: return "Unauthorized: Invalid API key."
        case .forbidden: return "Forbidden: Upgrade your plan."
        case .notFound(let msg): return "Not Found: \(msg)"
        case .parameterTooLong: return "Parameter Too Long."
        case .tooManyRequests: return "Too Many Requests: You’ve hit your limit."
        case .internalServerError: return "Server Error: Try again later."
        case .unknownError(_, let msg): return "Error: \(msg)"
        case .invalidResponse(statusCode: let statusCode, body: let body):
            return "Server returned status \(statusCode):\n\(body)"
        case .invalidSymbols(let symbols):
            return "Failed to load data for: \(symbols.joined(separator: ", "))"
        }
    }

    // Message-only access for displaying to the user
    var message: String {
        switch self {
        case .badRequest(let msg): return msg
        case .notFound(let msg): return msg
        case .unknownError(_, let msg): return msg
        default: return errorDescription ?? "Something went wrong."
        }
    }

    // JSON decoding from API
    enum CodingKeys: String, CodingKey {
        case code, message, status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(Int.self, forKey: .code)
        let message = try container.decodeIfPresent(String.self, forKey: .message) ?? "Unknown error"

        switch code {
        case 400: self = .badRequest(message: message)
        case 401: self = .unauthorized
        case 403: self = .forbidden
        case 404: self = .notFound(message: message)
        case 414: self = .parameterTooLong
        case 429: self = .tooManyRequests
        case 500: self = .internalServerError
        default: self = .unknownError(code: code, message: message)
        }
    }
}
