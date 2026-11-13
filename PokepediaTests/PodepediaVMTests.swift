//
//  PokepediaViewModelTests.swift
//  PokepediaViewModelTests
//
//  Created by SergiR on 12/11/2026.
//

import Foundation
import Testing
@testable import Pokepedia

struct PokepediaViewModelTests {
    // MARK: - ViewModels Tests

    @Test @MainActor func testPokemonListViewModelLoading() async {
        // Given
        let mockService = MockPokemonService(listResponse: .example)
        let viewModel = PokemonListViewModel(service: mockService)

        #expect(viewModel.pokemon.isEmpty)
        #expect(!viewModel.isLoading)

        // When
        await viewModel.loadInitialPokemon()

        // Then
        #expect(!viewModel.pokemon.isEmpty)
        #expect(viewModel.pokemon.count == PokemonListResponse.example.results.count)
        #expect(!viewModel.hasError)
        #expect(viewModel.errorMessage == nil)
    }

    @Test @MainActor func testPokemonListViewModelFiltering() async {
        // Given
        let mockService = MockPokemonService(listResponse: .example)
        let viewModel = PokemonListViewModel(service: mockService)
        await viewModel.loadInitialPokemon()

        // When
        viewModel.searchText = "char"

        // Then
        #expect(viewModel.filteredPokemon.count == 3) // charmander, charmeleon, charizard

        // When
        viewModel.searchText = "1"

        // Then
        #expect(viewModel.filteredPokemon.contains { $0.name == "bulbasaur" })

        // When
        viewModel.searchText = "non-existent-pokemon"

        // Then
        #expect(viewModel.filteredPokemon.isEmpty)
    }

    @Test @MainActor func testPokemonListViewModelSearchOnline() async {
        // Given
        let mockService = MockPokemonService(detailResponse: .example)
        let viewModel = PokemonListViewModel(service: mockService)
        viewModel.searchText = "bulbasaur"

        // When
        await viewModel.searchOnline()

        // Then
        #expect(viewModel.onlineSearchResult != nil)
        #expect(viewModel.onlineSearchResult?.name == "bulbasaur")
        #expect(viewModel.filteredPokemon.contains { $0.name == "bulbasaur" })

        // When
        viewModel.searchText = ""
        await viewModel.searchOnline()

        // Then
        #expect(viewModel.onlineSearchResult == nil)
    }

    @Test @MainActor func testPokemonListViewModelError() async {
        // Given
        let mockService = MockPokemonService(simulatedError: NetworkError.invalidURL)
        let viewModel = PokemonListViewModel(service: mockService)

        // When
        await viewModel.loadInitialPokemon()

        // Then
        #expect(viewModel.pokemon.isEmpty)
        #expect(viewModel.hasError)
        #expect(viewModel.errorMessage != nil)
    }

    @Test @MainActor func testPokemonDetailViewModelLoading() async {
        // Given
        let mockService = MockPokemonService(detailResponse: .example)
        let viewModel = PokemonDetailViewModel(pokemonIdentifier: "1", service: mockService)

        #expect(viewModel.pokemon == nil)
        #expect(!viewModel.isLoading)

        // When
        await viewModel.loadDetails()

        // Then
        #expect(viewModel.pokemon != nil)
        #expect(viewModel.pokemon?.name == "bulbasaur")
        #expect(!viewModel.hasError)
    }

    @Test @MainActor func testPokemonDetailViewModelError() async {
        // Given
        let mockService = MockPokemonService(simulatedError: NetworkError.badResponseIfAny)
        let viewModel = PokemonDetailViewModel(pokemonIdentifier: "invalid", service: mockService)

        // When
        await viewModel.loadDetails()

        // Then
        #expect(viewModel.pokemon == nil)
        #expect(viewModel.hasError)
        #expect(viewModel.errorMessage != nil)
    }
}

private extension NetworkError {
    static var badResponseIfAny: NetworkError {
        .invalidResponse
    }
}
