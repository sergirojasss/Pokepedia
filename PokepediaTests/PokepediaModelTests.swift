//
//  PokepediaModelTests.swift
//  PokepediaModelTests
//
//  Created by SergiR on 12/11/2026.
//

import Foundation
import Testing
@testable import Pokepedia

struct PokepediaModelTests {

    // MARK: - Models Tests

    @Test func testPokemonListItemIDExtraction() {
        // Given
        let item = PokemonListItem(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/")

        // Then
        #expect(item.id == 1)
        #expect(item.spriteURL?.absoluteString == "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png")
    }

    @Test func testPokemonListItemIDExtractionWithHighNumber() {
        // Given
        let item = PokemonListItem(name: "mewtwo", url: "https://pokeapi.co/api/v2/pokemon/150/")

        // Then
        #expect(item.id == 150)
        #expect(item.spriteURL?.absoluteString == "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/150.png")
    }

    @Test @MainActor func testPokemonListResponseDecoding() throws {
        // Given
        let json = """
        {
            "count": 1302,
            "next": "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
            "previous": null,
            "results": [
                {
                    "name": "bulbasaur",
                    "url": "https://pokeapi.co/api/v2/pokemon/1/"
                },
                {
                    "name": "ivysaur",
                    "url": "https://pokeapi.co/api/v2/pokemon/2/"
                }
            ]
        }
        """

        // When
        let data = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PokemonListResponse.self, from: data)

        // Then
        #expect(response.count == 1302)
        #expect(response.results.count == 2)
        #expect(response.results.first?.name == "bulbasaur")
        #expect(response.results.first?.id == 1)
    }

    @Test @MainActor func testPokemonDetailDecoding() throws {
        // Given
        let json = """
        {
            "id": 25,
            "name": "pikachu",
            "height": 4,
            "weight": 60,
            "base_experience": 112,
            "sprites": {
                "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png",
                "front_shiny": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/25.png",
                "other": {
                    "official-artwork": {
                        "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png",
                        "front_shiny": null
                    }
                }
            },
            "types": [
                {
                    "slot": 1,
                    "type": {
                        "name": "electric",
                        "url": "https://pokeapi.co/api/v2/type/13/"
                    }
                }
            ],
            "stats": [
                {
                    "base_stat": 35,
                    "effort": 0,
                    "stat": {
                        "name": "hp",
                        "url": "https://pokeapi.co/api/v2/stat/1/"
                    }
                }
            ],
            "abilities": [
                {
                    "slot": 1,
                    "is_hidden": false,
                    "ability": {
                        "name": "static",
                        "url": "https://pokeapi.co/api/v2/ability/9/"
                    }
                }
            ]
        }
        """

        // When
        let data = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let detail = try decoder.decode(PokemonDetail.self, from: data)

        // Then
        #expect(detail.id == 25)
        #expect(detail.name == "pikachu")
        #expect(detail.displayName == "Pikachu")
        #expect(detail.height == 4)
        #expect(detail.heightInMeters == 0.4)
        #expect(detail.weight == 60)
        #expect(detail.weightInKilograms == 6.0)
        #expect(detail.baseExperience == 112)
        #expect(detail.types.count == 1)
        #expect(detail.types.first?.type.name == "electric")
        #expect(detail.stats.first?.stat.name == "hp")
        #expect(detail.stats.first?.baseStat == 35)
        #expect(detail.abilities.first?.ability.name == "static")
        #expect(detail.sprites.preferredArtworkURL?.absoluteString == "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png")
    }
}
