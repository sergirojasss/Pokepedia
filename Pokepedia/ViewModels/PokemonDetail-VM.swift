//
//  PokemonDetail-VM.swift
//  Pokepedia
//
//  Created by SergiR on 12/11/2026.
//

import Foundation
import Observation

/// The view model that manages the retrieval and state of an individual Pokémon's details.
@Observable
@MainActor
public final class PokemonDetailViewModel {
    /// The unique identifier (name or numeric ID string) of the Pokémon to retrieve.
    public let pokemonIdentifier: String

    /// The loaded Pokémon detail data, or `nil` if not yet loaded.
    public private(set) var pokemon: PokemonDetail?

    /// Indicates whether details are currently being fetched over the network.
    public private(set) var isLoading: Bool = false

    /// An optional error message if the detail request fails.
    public var errorMessage: String?

    /// The network service conforming to `PokemonServiceProtocol`.
    private let service: PokemonServiceProtocol

    /// Indicates whether an error is currently active.
    public var hasError: Bool {
        errorMessage != nil
    }

    /// Initializes a new `PokemonDetailViewModel` using a name or numeric identifier string.
    /// - Parameters:
    ///   - pokemonIdentifier: The name or numeric ID string (e.g. "bulbasaur" or "1").
    ///   - service: The service to use for fetching details. Defaults to `PokemonService()`.
    public init(pokemonIdentifier: String, service: PokemonServiceProtocol = PokemonService()) {
        self.pokemonIdentifier = pokemonIdentifier
        self.service = service
    }

    /// Initializes a new `PokemonDetailViewModel` using a numeric ID.
    /// - Parameters:
    ///   - pokemonId: The numeric ID of the Pokémon (e.g. 1).
    ///   - service: The service to use for fetching details. Defaults to `PokemonService()`.
    public convenience init(pokemonId: Int, service: PokemonServiceProtocol = PokemonService()) {
        self.init(pokemonIdentifier: String(pokemonId), service: service)
    }

    /// Fetches the Pokémon details from PokéAPI.
    ///
    /// If details have already been fetched, this method returns early without refetching.
    public func loadDetails() async {
        guard pokemon == nil else { return }

        isLoading = true
        errorMessage = nil

        do {
            pokemon = try await service.fetchPokemonDetail(for: pokemonIdentifier)
        } catch is CancellationError {
            // Task was cancelled (e.g. user navigated back); cleanly ignore
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession network request was cancelled; cleanly ignore
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Retries fetching the Pokémon details, forcing a reload even if previously failed.
    public func retry() async {
        pokemon = nil
        await loadDetails()
    }
}
