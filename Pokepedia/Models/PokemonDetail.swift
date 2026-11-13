//
//  PokemonDetail.swift
//  Pokepedia
//
//  Created by SergiR on 12/11/2026.
//

import Foundation

/// Detailed model representing the complete data of an individual Pokémon.
public struct PokemonDetail: Codable, Identifiable, Sendable {
    /// The unique numeric identifier of the Pokémon.
    public let id: Int
    /// The name of the Pokémon (e.g. "bulbasaur").
    public let name: String
    /// The height of the Pokémon in decimetres.
    public let height: Int
    /// The weight of the Pokémon in hectograms.
    public let weight: Int
    /// The base experience gained for defeating this Pokémon, if available.
    public let baseExperience: Int?
    /// The sprite image representations for this Pokémon.
    public let sprites: PokemonSprites
    /// The elemental type assignments for this Pokémon.
    public let types: [PokemonTypeEntry]
    /// The base combat stats for this Pokémon.
    public let stats: [PokemonStatEntry]
    /// The abilities possessed by this Pokémon.
    public let abilities: [PokemonAbilityEntry]

    /// The height converted to meters for friendly UI display.
    public var heightInMeters: Double {
        Double(height) / 10.0
    }

    /// The weight converted to kilograms for friendly UI display.
    public var weightInKilograms: Double {
        Double(weight) / 10.0
    }

    /// The Pokémon's name formatted with the first letter capitalized.
    public var displayName: String {
        name.capitalized
    }

    /// Initializes a new `PokemonDetail` instance.
    /// - Parameters:
    ///   - id: The numeric identifier of the Pokémon.
    ///   - name: The name of the Pokémon.
    ///   - height: The height in decimetres.
    ///   - weight: The weight in hectograms.
    ///   - baseExperience: The base experience gained for defeating this Pokémon.
    ///   - sprites: The sprite images container.
    ///   - types: The list of type entries.
    ///   - stats: The list of combat stat entries.
    ///   - abilities: The list of ability entries.
    public init(
        id: Int,
        name: String,
        height: Int,
        weight: Int,
        baseExperience: Int? = nil,
        sprites: PokemonSprites,
        types: [PokemonTypeEntry] = [],
        stats: [PokemonStatEntry] = [],
        abilities: [PokemonAbilityEntry] = []
    ) {
        self.id = id
        self.name = name
        self.height = height
        self.weight = weight
        self.baseExperience = baseExperience
        self.sprites = sprites
        self.types = types
        self.stats = stats
        self.abilities = abilities
    }
}

// MARK: - Sprites Models

/// Container for sprite image URLs associated with a Pokémon.
public struct PokemonSprites: Codable, Sendable {
    /// The standard front-facing sprite image URL string.
    public let frontDefault: String?
    /// The shiny front-facing sprite image URL string.
    public let frontShiny: String?
    /// Additional nested sprite artwork representations.
    public let other: OtherSprites?

    /// Returns the best available artwork URL, preferring high-resolution official artwork.
    public var preferredArtworkURL: URL? {
        if let official = other?.officialArtwork?.frontDefault, let url = URL(string: official) {
            return url
        }
        if let frontDefault, let url = URL(string: frontDefault) {
            return url
        }
        return nil
    }

    /// Initializes a `PokemonSprites` instance.
    /// - Parameters:
    ///   - frontDefault: The standard front sprite URL string.
    ///   - frontShiny: The shiny front sprite URL string.
    ///   - other: Additional nested artwork collections.
    public init(frontDefault: String? = nil, frontShiny: String? = nil, other: OtherSprites? = nil) {
        self.frontDefault = frontDefault
        self.frontShiny = frontShiny
        self.other = other
    }
}

/// Container for alternative sprite collections such as official artwork.
public struct OtherSprites: Codable, Sendable {
    /// High-resolution official Pokémon artwork.
    public let officialArtwork: OfficialArtwork?

    enum CodingKeys: String, CodingKey {
        case officialArtwork = "official-artwork"
    }

    /// Initializes an `OtherSprites` instance.
    /// - Parameter officialArtwork: The official artwork sprites.
    public init(officialArtwork: OfficialArtwork? = nil) {
        self.officialArtwork = officialArtwork
    }
}

/// Container for official Pokémon artwork images.
public struct OfficialArtwork: Codable, Sendable {
    /// High-resolution official front-facing image URL string.
    public let frontDefault: String?
    /// High-resolution shiny front-facing image URL string.
    public let frontShiny: String?

    /// Initializes an `OfficialArtwork` instance.
    /// - Parameters:
    ///   - frontDefault: The standard artwork URL string.
    ///   - frontShiny: The shiny artwork URL string.
    public init(frontDefault: String? = nil, frontShiny: String? = nil) {
        self.frontDefault = frontDefault
        self.frontShiny = frontShiny
    }
}

// MARK: - Type, Stat, and Ability Entries

/// Describes an elemental type assigned to a Pokémon.
/// A resource representing a Pokémon type.
public typealias PokemonTypeResource = NamedAPIResource

public struct PokemonTypeEntry: Codable, Identifiable, Sendable {
    /// The slot order for this type assignment.
    public let slot: Int
    /// The referenced type resource containing the name and URL.
    public let type: PokemonTypeResource

    /// An identifier derived from the slot index.
    public var id: Int { slot }

    /// Initializes a `PokemonTypeEntry` instance.
    /// - Parameters:
    ///   - slot: The slot index of the type.
    ///   - type: The `NamedAPIResource` describing the type.
    public init(slot: Int, type: PokemonTypeResource) {
        self.slot = slot
        self.type = type
    }
}

/// A resource representing a Pokémon stat.
public typealias PokemonStatResource = NamedAPIResource

/// Describes a combat stat value for a Pokémon.
public struct PokemonStatEntry: Codable, Identifiable, Sendable {
    /// The base value of this combat stat.
    public let baseStat: Int
    /// The effort point (EV) yield for this stat.
    public let effort: Int
    /// The referenced stat resource containing the name and URL.
    public let stat: PokemonStatResource

    /// The name of the stat used as its unique identifier.
    public var id: String { stat.name }

    /// Initializes a `PokemonStatEntry` instance.
    /// - Parameters:
    ///   - baseStat: The numeric base stat value.
    ///   - effort: The effort points gained.
    ///   - stat: The `NamedAPIResource` describing the stat.
    public init(baseStat: Int, effort: Int, stat: PokemonStatResource) {
        self.baseStat = baseStat
        self.effort = effort
        self.stat = stat
    }
}

/// A resource representing a Pokémon ability.
public typealias PokemonAbilityResource = NamedAPIResource

/// Describes an ability possessed by a Pokémon.
public struct PokemonAbilityEntry: Codable, Identifiable, Sendable {
    /// The referenced ability resource containing the name and URL.
    public let ability: PokemonAbilityResource
    /// Whether this is a hidden ability.
    public let isHidden: Bool
    /// The slot order for this ability.
    public let slot: Int

    /// The name of the ability used as its unique identifier.
    public var id: String { ability.name }

    /// Initializes a `PokemonAbilityEntry` instance.
    /// - Parameters:
    ///   - ability: The `NamedAPIResource` describing the ability.
    ///   - isHidden: Flag indicating if the ability is hidden.
    ///   - slot: The slot index of this ability.
    public init(ability: PokemonAbilityResource, isHidden: Bool, slot: Int) {
        self.ability = ability
        self.isHidden = isHidden
        self.slot = slot
    }
}

// MARK: - Example Data for Previews and Testing
extension PokemonDetail {
    /// An example `PokemonDetail` instance for SwiftUI previews and tests.
    public static let example = PokemonDetail(
        id: 1,
        name: "bulbasaur",
        height: 7,
        weight: 69,
        baseExperience: 64,
        sprites: PokemonSprites(
            frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png",
            frontShiny: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/1.png",
            other: OtherSprites(
                officialArtwork: OfficialArtwork(
                    frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png",
                    frontShiny: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/1.png"
                )
            )
        ),
        types: [
            PokemonTypeEntry(slot: 1, type: PokemonTypeResource(name: "grass", url: "https://pokeapi.co/api/v2/type/12/")),
            PokemonTypeEntry(slot: 2, type: PokemonTypeResource(name: "poison", url: "https://pokeapi.co/api/v2/type/4/"))
        ],
        stats: [
            PokemonStatEntry(baseStat: 45, effort: 0, stat: PokemonStatResource(name: "hp", url: "https://pokeapi.co/api/v2/stat/1/")),
            PokemonStatEntry(baseStat: 49, effort: 0, stat: PokemonStatResource(name: "attack", url: "https://pokeapi.co/api/v2/stat/2/")),
            PokemonStatEntry(baseStat: 49, effort: 0, stat: PokemonStatResource(name: "defense", url: "https://pokeapi.co/api/v2/stat/3/")),
            PokemonStatEntry(baseStat: 65, effort: 1, stat: PokemonStatResource(name: "special-attack", url: "https://pokeapi.co/api/v2/stat/4/")),
            PokemonStatEntry(baseStat: 65, effort: 0, stat: PokemonStatResource(name: "special-defense", url: "https://pokeapi.co/api/v2/stat/5/")),
            PokemonStatEntry(baseStat: 45, effort: 0, stat: PokemonStatResource(name: "speed", url: "https://pokeapi.co/api/v2/stat/6/"))
        ],
        abilities: [
            PokemonAbilityEntry(ability: PokemonAbilityResource(name: "overgrow", url: "https://pokeapi.co/api/v2/ability/65/"), isHidden: false, slot: 1),
            PokemonAbilityEntry(ability: PokemonAbilityResource(name: "chlorophyll", url: "https://pokeapi.co/api/v2/ability/34/"), isHidden: true, slot: 3)
        ]
    )
}
