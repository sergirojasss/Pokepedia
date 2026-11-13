//
//  PokepediaServiceTests.swift
//  PokepediaServiceTests
//
//  Created by SergiR on 12/11/2026.
//

import Foundation
import Testing
@testable import Pokepedia

struct PokepediaServiceTests {
    // MARK: - Services Tests

    @Test @MainActor func testMockPokemonService() async throws {
        // Given
        let service = MockPokemonService()

        // When
        let list = try await service.fetchPokemonList()

        // Then
        #expect(!list.results.isEmpty)

        // When
        let detail = try await service.fetchPokemonDetail(for: 1)

        // Then
        #expect(detail.id == 1)
        #expect(detail.name == "bulbasaur")
    }

    @Test @MainActor  func testMockPokemonServiceError() async {
        // Given
        let service = MockPokemonService(simulatedError: NetworkError.invalidURL)

        // When / Then
        await #expect(throws: NetworkError.self) {
            try await service.fetchPokemonList()
        }
    }

    // MARK: - Cache Tests

    @Test @MainActor func testAPICacheStoreAndRetrieve() async {
        // Given
        let cache = APICache()
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon/1")!
        let detail = PokemonDetail.example

        // When
        await cache.set(detail, for: url, ttl: 300)
        let cached = await cache.get(PokemonDetail.self, for: url)

        // Then
        #expect(cached != nil)
        #expect(cached?.id == detail.id)
    }

    @Test @MainActor func testAPICacheExpiration() async {
        // Given
        let cache = APICache()
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon/2")!
        let detail = PokemonDetail.example

        // When
        // Set with negative TTL so it is already expired.
        await cache.set(detail, for: url, ttl: -1)
        let cached = await cache.get(PokemonDetail.self, for: url)

        // Then
        #expect(cached == nil)
    }

    @Test @MainActor func testAPICacheClear() async {
        // Given
        let cache = APICache()
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon/3")!
        let detail = PokemonDetail.example

        // When
        await cache.set(detail, for: url, ttl: 300)
        await cache.clear()
        let cached = await cache.get(PokemonDetail.self, for: url)

        // Then
        #expect(cached == nil)
    }
}
