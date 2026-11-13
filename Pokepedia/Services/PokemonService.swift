//
//  PokemonService.swift
//  Pokepedia
//
//  Created by SergiR on 12/11/2026.
//

import Foundation

/// Defines the service interface for fetching Pokémon data from PokéAPI.
public protocol PokemonServiceProtocol: Sendable {
    /// Fetches a paginated list of Pokémon.
    /// - Parameters:
    ///   - limit: The maximum number of Pokémon to fetch.
    ///   - offset: The offset index to start pagination from.
    /// - Returns: A `PokemonListResponse` containing the paginated Pokémon entries.
    /// - Throws: An error if the request fails or data cannot be decoded.
    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse

    /// Fetches detailed information for a specific Pokémon using its identifier or name.
    /// - Parameter idOrName: The name or numeric ID string of the Pokémon (e.g., "1" or "bulbasaur").
    /// - Returns: A `PokemonDetail` containing the Pokémon's attributes.
    /// - Throws: An error if the request fails or data cannot be decoded.
    func fetchPokemonDetail(for idOrName: String) async throws -> PokemonDetail
}

public extension PokemonServiceProtocol {
    /// Fetches the initial paginated list of Pokémon with default pagination parameters.
    /// - Returns: A `PokemonListResponse` containing the first page of Pokémon.
    /// - Throws: An error if the request fails or data cannot be decoded.
    func fetchPokemonList() async throws -> PokemonListResponse {
        try await fetchPokemonList(limit: 20, offset: 0)
    }

    /// Fetches detailed information for a specific Pokémon using its numeric identifier.
    /// - Parameter id: The numeric ID of the Pokémon.
    /// - Returns: A `PokemonDetail` containing the Pokémon's attributes.
    /// - Throws: An error if the request fails or data cannot be decoded.
    func fetchPokemonDetail(for id: Int) async throws -> PokemonDetail {
        try await fetchPokemonDetail(for: String(id))
    }
}

/// A service responsible for retrieving Pokémon list and detail information from PokéAPI.
public struct PokemonService: PokemonServiceProtocol {
    /// The `URLSession` instance used for performing network requests.
    private let session: URLSession

    /// The base URL string pointing to the PokéAPI v2 root endpoint.
    private let baseURLString = "https://pokeapi.co/api/v2"

    /// Initializes a new instance of `PokemonService`.
    /// - Parameter session: The `URLSession` configured for network calls. Defaults to `.shared`.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches a paginated list of Pokémon from PokéAPI.
    ///
    /// Constructs a query to `/pokemon` with the provided `limit` and `offset` query parameters.
    ///
    /// - Parameters:
    ///   - limit: The maximum number of Pokémon to fetch. Defaults to 20.
    ///   - offset: The index offset of the first item to return. Defaults to 0.
    /// - Returns: A `PokemonListResponse` containing the list of Pokémon items and pagination metadata.
    /// - Throws: `NetworkError.invalidURL` if the URL cannot be constructed, or any network/decoding error.
    public func fetchPokemonList(limit: Int = 20, offset: Int = 0) async throws -> PokemonListResponse {
        guard var components = URLComponents(string: "\(baseURLString)/pokemon") else {
            throw NetworkError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        return try await session.decode(PokemonListResponse.self, from: url)
    }

    /// Fetches complete detail for a specific Pokémon identified by name or numeric ID.
    ///
    /// - Parameter idOrName: The name or numeric ID string of the Pokémon (e.g. "pikachu" or "25").
    /// - Returns: A `PokemonDetail` instance populated with data from PokéAPI.
    /// - Throws: `NetworkError.invalidURL` if the identifier is empty or cannot produce a valid URL,
    ///           or any error encountered during networking or JSON decoding.
    public func fetchPokemonDetail(for idOrName: String) async throws -> PokemonDetail {
        let cleanedIdentifier = idOrName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleanedIdentifier.isEmpty,
              let url = URL(string: "\(baseURLString)/pokemon/\(cleanedIdentifier)") else {
            throw NetworkError.invalidURL
        }

        return try await session.decode(PokemonDetail.self, from: url)
    }
}

// MARK: - Mock Service for Previews and Unit Testing

/// A mock implementation of `PokemonServiceProtocol` that returns static sample data without making network requests.
public struct MockPokemonService: PokemonServiceProtocol {
    /// Custom sample list response to return, defaulting to `PokemonListResponse.example`.
    public var listResponse: PokemonListResponse
    /// Custom sample detail response to return, defaulting to `PokemonDetail.example`.
    public var detailResponse: PokemonDetail
    /// Optional error to throw for simulating network or decoding failures in tests.
    public var simulatedError: Error?

    /// Initializes a `MockPokemonService` instance.
    /// - Parameters:
    ///   - listResponse: The list response to return. Defaults to `PokemonListResponse.example`.
    ///   - detailResponse: The detail response to return. Defaults to `PokemonDetail.example`.
    ///   - simulatedError: An optional error to throw when methods are invoked. Defaults to `nil`.
    public init(
        listResponse: PokemonListResponse = .example,
        detailResponse: PokemonDetail = .example,
        simulatedError: Error? = nil
    ) {
        self.listResponse = listResponse
        self.detailResponse = detailResponse
        self.simulatedError = simulatedError
    }

    /// Returns the mocked list response, or throws the simulated error if one is set.
    /// - Parameters:
    ///   - limit: Ignored in the mock implementation.
    ///   - offset: Ignored in the mock implementation.
    /// - Returns: The mocked `PokemonListResponse`.
    /// - Throws: The `simulatedError` if configured.
    public func fetchPokemonList(limit: Int = 20, offset: Int = 0) async throws -> PokemonListResponse {
        if let simulatedError {
            throw simulatedError
        }
        return listResponse
    }

    /// Returns the mocked detail response, or throws the simulated error if one is set.
    /// - Parameter idOrName: Ignored in the mock implementation.
    /// - Returns: The mocked `PokemonDetail`.
    /// - Throws: The `simulatedError` if configured.
    public func fetchPokemonDetail(for idOrName: String) async throws -> PokemonDetail {
        if let simulatedError {
            throw simulatedError
        }
        return detailResponse
    }
}
