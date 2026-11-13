//
//  PokemonListResponse.swift
//  Pokepedia
//
//  Created by SergiR on 12/11/2026.
//

import Foundation

/// A type alias for an individual Pokémon item in the paginated list.
public typealias PokemonListItem = NamedAPIResource
extension PokemonListItem {
    /// Computes the default artwork/sprite URL for this Pokémon.
    public var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }
}


/// Represents the paginated response returned by the PokéAPI `/pokemon` endpoint.
public struct PokemonListResponse: Codable, Sendable {
    /// The total count of Pokémon available in PokéAPI.
    public let count: Int
    /// The URL string for the next page of results, or `nil` if there are no more pages.
    public let next: String?
    /// The URL string for the previous page of results, or `nil` if this is the first page.
    public let previous: String?
    /// The list of Pokémon entries for the current page.
    public let results: [PokemonListItem]

    /// Initializes a new `PokemonListResponse`.
    /// - Parameters:
    ///   - count: The total count of Pokémon.
    ///   - next: The URL string for the next page, if any.
    ///   - previous: The URL string for the previous page, if any.
    ///   - results: The array of Pokémon list items.
    public init(count: Int, next: String? = nil, previous: String? = nil, results: [PokemonListItem]) {
        self.count = count
        self.next = next
        self.previous = previous
        self.results = results
    }
}

// MARK: - Example Data for Previews and Testing
extension PokemonListResponse {
    /// An example `PokemonListResponse` instance for SwiftUI previews and tests.
    public static let example = PokemonListResponse(
        count: 1302,
        next: "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
        previous: nil,
        results: [
            PokemonListItem(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/"),
            PokemonListItem(name: "ivysaur", url: "https://pokeapi.co/api/v2/pokemon/2/"),
            PokemonListItem(name: "venusaur", url: "https://pokeapi.co/api/v2/pokemon/3/"),
            PokemonListItem(name: "charmander", url: "https://pokeapi.co/api/v2/pokemon/4/"),
            PokemonListItem(name: "charmeleon", url: "https://pokeapi.co/api/v2/pokemon/5/"),
            PokemonListItem(name: "charizard", url: "https://pokeapi.co/api/v2/pokemon/6/"),
            PokemonListItem(name: "squirtle", url: "https://pokeapi.co/api/v2/pokemon/7/"),
            PokemonListItem(name: "wartortle", url: "https://pokeapi.co/api/v2/pokemon/8/"),
            PokemonListItem(name: "blastoise", url: "https://pokeapi.co/api/v2/pokemon/9/")
        ]
    )
}

extension PokemonListItem {
    /// An example `PokemonListItem` instance for SwiftUI previews and tests.
    public static let example = PokemonListItem(
        name: "bulbasaur",
        url: "https://pokeapi.co/api/v2/pokemon/1/"
    )
}
