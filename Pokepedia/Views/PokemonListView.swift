//
//  PokemonListView.swift
//  Pokepedia
//
//  Created by SergiR on 12/11/2026.
//

import SwiftUI

/// The main Pokémon list screen displaying paginated Pokémon with search and navigation to detail.
///
///  `AsyncImage`, `.searchable`, pull-to-refresh, online search with cancellation, and infinite scrolling.
@MainActor
public struct PokemonListView: View {
    /// The view model managing list state, pagination, and search filtering.
    @State private var viewModel: PokemonListViewModel

    /// Initializes `PokemonListView` with a default view model.
    public init() {
        _viewModel = State(wrappedValue: PokemonListViewModel())
    }

    /// Initializes `PokemonListView` with a custom view model.
    /// - Parameter viewModel: The custom `PokemonListViewModel` to use.
    public init(viewModel: PokemonListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.pokemon.isEmpty {
                    initialLoadingView
                } else if viewModel.pokemon.isEmpty, let error = viewModel.errorMessage {
                    initialErrorView(error)
                } else if viewModel.isSearchingOnline && viewModel.filteredPokemon.isEmpty {
                    searchingOnlineView
                } else if viewModel.filteredPokemon.isEmpty && !viewModel.searchText.isEmpty {
                    noSearchResultsView
                } else {
                    pokemonList
                }
            }
            .navigationTitle("Poképedia")
            .searchable(text: $viewModel.searchText, prompt: "Search by name or number")
            .task(id: viewModel.searchText) {
                await viewModel.searchOnline()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadInitialPokemon()
            }
        }
    }

    // MARK: - Subviews

    /// The scrollable list displaying Pokémon entries.
    private var pokemonList: some View {
        List {
            ForEach(viewModel.filteredPokemon) { item in
                NavigationLink {
                    PokemonDetailView(item: item)
                } label: {
                    pokemonRow(for: item)
                }
                .task {
                    await viewModel.loadMoreIfNeeded(currentItem: item)
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    /// Renders an individual row in the Pokémon list.
    /// - Parameter item: The `PokemonListItem` to render.
    @ViewBuilder
    private func pokemonRow(for item: PokemonListItem) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 54, height: 54)

                AsyncImage(url: item.spriteURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name.capitalized)
                    .font(.headline)

                Text(String(format: "#%03d", item.id))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// The initial loading screen displayed when fetching the first page of data.
    private var initialLoadingView: some View {
        ProgressView("Catching 'em all...")
            .controlSize(.large)
    }

    /// The loading view shown when searching directly against PokéAPI.
    private var searchingOnlineView: some View {
        ProgressView("Searching PokéAPI...")
            .controlSize(.large)
    }

    /// The error screen displayed when the initial network request fails.
    /// - Parameter error: The error message to present.
    @ViewBuilder
    private func initialErrorView(_ error: String) -> some View {
        ContentUnavailableView {
            Label("Failed to Load", systemImage: "wifi.exclamationmark")
        } description: {
            Text(error)
        } actions: {
            Button("Retry", systemImage: "arrow.clockwise") {
                Task {
                    await viewModel.loadInitialPokemon()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// The empty state displayed when search produces zero matching items.
    private var noSearchResultsView: some View {
        ContentUnavailableView.search(text: viewModel.searchText)
    }
}

/// Backward compatibility alias so existing references to `ContentView` continue to function.
public typealias ContentView = PokemonListView

#Preview {
    PokemonListView(
        viewModel: PokemonListViewModel(
            service: MockPokemonService(listResponse: .example)
        )
    )
}
