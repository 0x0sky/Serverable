// File: APIError.swift
// Module: APIModels
// Description: Common error type for API layer.

import Foundation

public enum APIError: Error, Sendable, Codable {
    case networkFailure(String)
    case decodingFailure(String)
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .networkFailure(let msg): return "Network failure: \(msg)"
        case .decodingFailure(let msg): return "Decoding failure: \(msg)"
        case .unknown(let msg): return "Unknown error: \(msg)"
        }
    }
}
