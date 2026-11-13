//
//  PokemonDetailView.swift
//  Pokepedia
//
//  Created by SergiR on 12/11/2026.
//

import SwiftUI

/// Displays comprehensive details for an individual Pokémon.
///
/// `AsyncImage` asynchronous image loading, and responsive states.
@MainActor
public struct PokemonDetailView: View {
    /// The view model managing Pokémon detail state and network loading.
    @State private var viewModel: PokemonDetailViewModel

    /// Initializes the detail view with a view model.
    /// - Parameter viewModel: The configured `PokemonDetailViewModel`.
    public init(viewModel: PokemonDetailViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    /// Initializes the detail view using a `PokemonListItem`.
    /// - Parameters:
    ///   - item: The `PokemonListItem` to display.
    ///   - service: The network service to use. Defaults to `PokemonService()`.
    public init(item: PokemonListItem, service: PokemonServiceProtocol = PokemonService()) {
        _viewModel = State(wrappedValue: PokemonDetailViewModel(pokemonIdentifier: String(item.id), service: service))
    }

    public var body: some View {
        Group {
            if let pokemon = viewModel.pokemon {
                pokemonContent(pokemon)
            } else if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else {
                loadingView
            }
        }
        .navigationTitle(viewModel.pokemon?.displayName ?? "Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetails()
        }
    }

    // MARK: - Content Subviews

    /// Renders the main detail content scroll view for the loaded Pokémon.
    /// - Parameter pokemon: The loaded `PokemonDetail` model.
    @ViewBuilder
    private func pokemonContent(_ pokemon: PokemonDetail) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                artworkHeader(for: pokemon)

                typesRow(for: pokemon.types)

                aboutSection(for: pokemon)

                if !pokemon.stats.isEmpty {
                    statsSection(for: pokemon.stats)
                }

                if !pokemon.abilities.isEmpty {
                    abilitiesSection(for: pokemon.abilities)
                }
            }
            .padding()
        }
    }

    /// Renders the top artwork image header.
    /// - Parameter pokemon: The Pokémon whose artwork to render.
    @ViewBuilder
    private func artworkHeader(for pokemon: PokemonDetail) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 220, height: 220)

                AsyncImage(url: pokemon.sprites.preferredArtworkURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .padding(.top, 8)

            Text(String(format: "#%03d", pokemon.id))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            Text(pokemon.displayName)
                .font(.title)
                .fontWeight(.heavy)
        }
    }

    /// Renders horizontal pills for each Pokémon elemental type.
    /// - Parameter types: The list of type entries.
    @ViewBuilder
    private func typesRow(for types: [PokemonTypeEntry]) -> some View {
        HStack(spacing: 8) {
            ForEach(types) { entry in
                Text(entry.type.name.capitalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(typeColor(for: entry.type.name), in: Capsule())
            }
        }
    }

    /// Renders the Physical Attributes / Dimensions card.
    /// - Parameter pokemon: The Pokémon detail model.
    @ViewBuilder
    private func aboutSection(for pokemon: PokemonDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)

            HStack {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f m", pokemon.heightInMeters))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Height")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 36)

                VStack(spacing: 4) {
                    Text(String(format: "%.1f kg", pokemon.weightInKilograms))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                if let exp = pokemon.baseExperience {
                    Divider()
                        .frame(height: 36)

                    VStack(spacing: 4) {
                        Text("\(exp)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Base Exp")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Renders the combat stats progress bars.
    /// - Parameter stats: The array of stats.
    @ViewBuilder
    private func statsSection(for stats: [PokemonStatEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Base Stats")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(stats) { entry in
                    HStack(spacing: 12) {
                        Text(formatStatName(entry.stat.name))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 90, alignment: .leading)
                            .foregroundStyle(.secondary)

                        Text("\(entry.baseStat)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 32, alignment: .trailing)

                        ProgressView(value: Double(entry.baseStat), total: 255)
                            .tint(statColor(for: entry.baseStat))
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Renders the Pokémon abilities list.
    /// - Parameter abilities: The array of abilities.
    @ViewBuilder
    private func abilitiesSection(for abilities: [PokemonAbilityEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Abilities")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(abilities) { entry in
                    HStack {
                        Text(entry.ability.name.replacingOccurrences(of: "-", with: " ").capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        if entry.isHidden {
                            Text("Hidden")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.2), in: Capsule())
                        }
                    }
                    .padding(.vertical, 4)

                    if entry.id != abilities.last?.id {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Renders the centered progress loading indicator.
    private var loadingView: some View {
        ProgressView("Catching Pokémon...")
            .controlSize(.large)
    }

    /// Renders an error view with a retry action button.
    /// - Parameter message: The error message to display.
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Failed to Load", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", systemImage: "arrow.clockwise") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers

    /// Formats PokéAPI raw stat keys into user-friendly abbreviations.
    /// - Parameter rawName: The stat name from the API (e.g. "special-attack").
    /// - Returns: A formatted string suitable for the stat list.
    private func formatStatName(_ rawName: String) -> String {
        switch rawName {
        case "hp": return "HP"
        case "attack": return "Attack"
        case "defense": return "Defense"
        case "special-attack": return "Sp. Atk"
        case "special-defense": return "Sp. Def"
        case "speed": return "Speed"
        default: return rawName.capitalized
        }
    }

    /// Determines the accent color of a stat bar based on its numeric value.
    /// - Parameter value: The base stat value.
    /// - Returns: A `Color` indicating stat strength.
    private func statColor(for value: Int) -> Color {
        if value < 50 {
            return .red
        } else if value < 90 {
            return .orange
        } else {
            return .green
        }
    }

    /// Returns a thematic color corresponding to a Pokémon elemental type.
    /// - Parameter type: The type name (e.g. "grass", "fire").
    /// - Returns: A `Color` representing the elemental type.
    private func typeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "grass": return .green
        case "poison": return .purple
        case "fire": return .red
        case "water": return .blue
        case "electric": return .yellow
        case "bug": return Color(red: 0.6, green: 0.7, blue: 0.1)
        case "normal": return .gray
        case "ground": return Color(red: 0.8, green: 0.6, blue: 0.3)
        case "fairy": return .pink
        case "fighting": return Color(red: 0.7, green: 0.2, blue: 0.2)
        case "psychic": return Color(red: 0.9, green: 0.3, blue: 0.5)
        case "rock": return Color(red: 0.7, green: 0.6, blue: 0.4)
        case "ghost": return Color(red: 0.4, green: 0.3, blue: 0.6)
        case "ice": return Color(red: 0.4, green: 0.8, blue: 0.8)
        case "dragon": return Color(red: 0.4, green: 0.2, blue: 0.9)
        case "steel": return Color(red: 0.6, green: 0.7, blue: 0.8)
        case "dark": return Color(red: 0.3, green: 0.2, blue: 0.2)
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        PokemonDetailView(
            viewModel: PokemonDetailViewModel(
                pokemonIdentifier: "1",
                service: MockPokemonService(detailResponse: .example)
            )
        )
    }
}
