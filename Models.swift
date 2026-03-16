import Foundation

// MARK: - Connection

enum ConnectionType: String, CaseIterable, Codable, Identifiable {
    case offline
    case microsoft

    var id: String { rawValue }
}

// MARK: - Server

struct ServerRecord: Codable, Identifiable {
    var id = UUID()
    var name: String
    var ip: String
    var port: Int
}

// MARK: - API Envelope

struct APIEnvelope<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}

struct APIErrorEnvelope: Codable {
    let success: Bool
    let error: String?
}

// MARK: - API Errors

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case server(String)
    case decoding(String)
}

// MARK: - Auth

struct AuthRedeemResponse: Codable {
    let token: String
}

struct AuthMeResponse: Codable {
    let id: String
    let username: String
}

// MARK: - Accounts

struct AccountsResponse: Codable {
    let accounts: [Account]
}

struct Account: Codable, Identifiable {
    let id: String
    let type: String
    let username: String
}

// MARK: - Microsoft Link

struct LinkStartResponse: Codable {
    let url: String
}

struct LinkStatusResponse: Codable {
    let status: String
}

struct UnlinkResponse: Codable {
    let success: Bool
}

// MARK: - Bot

struct BotStartResponse: Codable {
    let success: Bool
}

struct BotActionResponse: Codable {
    let success: Bool
}

struct BotStatusResponse: Codable {
    let running: Bool
    let server: String?
    let memoryUsage: Int?
}

// MARK: - Health

struct HealthResponse: Codable {
    let status: String
    let memoryUsage: Int?
}
