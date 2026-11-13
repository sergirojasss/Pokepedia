//
//  PokemonList-VM.swift
//  Pokepedia
//
//  Created by SergiR on 12/11/2026.
//

import Foundation
import Observation

/// The view model that manages state, data fetching, and online searching for the Pokémon list view.
///
/// Implemented following Paul Hudson's modern Swift Concurrency and Observation architecture.
@Observable
@MainActor
public final class PokemonListViewModel {
    /// The collection of all Pokémon loaded so far through pagination.
    public private(set) var pokemon: [PokemonListItem] = []

    /// A Pokémon found via direct online search by name or ID.
    public private(set) var onlineSearchResult: PokemonListItem?

    /// Indicates whether the initial data load is in progress.
    public private(set) var isLoading: Bool = false

    /// Indicates whether an additional page of data is being loaded.
    public private(set) var isLoadingMore: Bool = false

    /// Indicates whether an online search network request is currently executing.
    public private(set) var isSearchingOnline: Bool = false

    /// An optional error message to present to the user if a network call fails.
    public var errorMessage: String?

    /// The current search query string entered by the user.
    public var searchText: String = ""

    /// Indicates whether there are more pages available to load from PokéAPI.
    public private(set) var hasMorePages: Bool = true

    /// The current pagination offset.
    private var offset: Int = 0

    /// The number of items to retrieve per page.
    private let pageSize: Int = 20

    /// The network service conforming to `PokemonServiceProtocol`.
    private let service: PokemonServiceProtocol

    /// Returns the filtered list of Pokémon based on local cache and online search results.
    public var filteredPokemon: [PokemonListItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return pokemon
        }

        var results = pokemon.filter { item in
            item.name.localizedCaseInsensitiveContains(trimmed) || String(item.id).contains(trimmed)
        }

        // Include the online search result if not already present in the local matches
        if let online = onlineSearchResult, !results.contains(where: { $0.id == online.id }) {
            results.append(online)
        }

        return results
    }

    /// Indicates whether an error is currently active.
    public var hasError: Bool {
        errorMessage != nil
    }

    /// Initializes a new `PokemonListViewModel`.
    /// - Parameter service: The service instance to use for network calls. Defaults to `PokemonService()`.
    public init(service: PokemonServiceProtocol = PokemonService()) {
        self.service = service
    }

    /// Loads the initial page of Pokémon from PokéAPI if the list is currently empty.
    ///
    /// Resets pagination state and fetches the first batch of results.
    public func loadInitialPokemon() async {
        guard pokemon.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        offset = 0

        do {
            let response = try await service.fetchPokemonList(limit: pageSize, offset: offset)
            pokemon = response.results
            offset += response.results.count
            hasMorePages = response.next != nil
        } catch is CancellationError {
            // Task cancelled; ignore
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession cancelled; ignore
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Loads the next page of Pokémon, appending the results to the existing collection.
    ///
    /// Ignores requests if a load is already active or if all pages have been fetched.
    public func loadMorePokemon() async {
        guard !isLoading && !isLoadingMore && hasMorePages else { return }

        isLoadingMore = true

        do {
            let response = try await service.fetchPokemonList(limit: pageSize, offset: offset)
            pokemon.append(contentsOf: response.results)
            offset += response.results.count
            hasMorePages = response.next != nil
        } catch is CancellationError {
            // Task cancelled; ignore
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession cancelled; ignore
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    /// Performs an online search against PokéAPI using the current `searchText`.
    ///
    /// This method incorporates a 350-millisecond debounce to avoid unnecessary network calls
    /// while the user is actively typing. If the search query is cleared (e.g. by tapping the clear 'X' button)
    /// or if a subsequent keystroke is registered, the active task is automatically cancelled.
    public func searchOnline() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !query.isEmpty else {
            onlineSearchResult = nil
            isSearchingOnline = false
            return
        }

        // Debounce to allow rapid typing without triggering requests per keystroke
        do {
            try await Task.sleep(for: .milliseconds(350))
        } catch {
            // Task was cancelled during debounce delay (e.g. user typed another letter or tapped 'X')
            return
        }

        isSearchingOnline = true
        defer { isSearchingOnline = false }

        do {
            let detail = try await service.fetchPokemonDetail(for: query)
            let item = PokemonListItem(
                name: detail.name,
                url: "https://pokeapi.co/api/v2/pokemon/\(detail.id)/"
            )
            onlineSearchResult = item
        } catch is CancellationError {
            // The search was cancelled mid-flight (e.g. user modified text or cleared query)
            onlineSearchResult = nil
        } catch let urlError as URLError where urlError.code == .cancelled {
            // The underlying URLSession task was cancelled
            onlineSearchResult = nil
        } catch {
            // Pokémon not found or network failure
            onlineSearchResult = nil
        }
    }

    /// Checks if pagination should trigger when the user scrolls near the end of the list.
    /// - Parameter currentItem: The item currently appearing on screen.
    public func loadMoreIfNeeded(currentItem: PokemonListItem) async {
        guard let lastItem = pokemon.last, lastItem.id == currentItem.id else { return }
        // Don't paginate while searching to avoid unexpected list changes
        guard searchText.isEmpty else { return }
        await loadMorePokemon()
    }

    /// Refreshes the entire Pokémon list from the beginning, typically invoked via pull-to-refresh.
    /// Also clears the API cache to guarantee fresh server data.
    public func refresh() async {
        offset = 0
        hasMorePages = true
        errorMessage = nil
        onlineSearchResult = nil

        await APICache.shared.clear()

        do {
            let response = try await service.fetchPokemonList(limit: pageSize, offset: 0)
            pokemon = response.results
            offset = response.results.count
            hasMorePages = response.next != nil
        } catch is CancellationError {
            // Task cancelled; ignore
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession cancelled; ignore
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
