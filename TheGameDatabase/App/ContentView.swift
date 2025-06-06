//
//  ContentView.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.dbClient) var dbClient
    @Environment(ContentViewModel.self) var viewModel

    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Error>?

    var body: some View {
        ScrollView(.vertical) {
            VStack {
                searchSection
                searchButton
                contentSection
                loadingIndicator
            }
            .padding()
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    @ViewBuilder
    private var searchSection: some View {
        TextField("Search for a character", text: $searchText)
            .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var searchButton: some View {
        Button("Search") {
            performSearch()
        }
        .disabled(searchText.isEmpty)
    }

    @ViewBuilder
    private var contentSection: some View {
        if let character = viewModel.characterDTO {
            characterDetails(for: character)
        } else if let error = viewModel.error {
            errorView(for: error)
        }
    }

    @ViewBuilder
    private var loadingIndicator: some View {
        if viewModel.isLoading {
            ProgressView()
        }
    }

    @ViewBuilder
    private func characterDetails(for character: GameCharacterDTO) -> some View {
        VStack(spacing: 12) {
            HStack {
                if let mugshot = character.mugshot, let imageID = mugshot.imageID {
                    image(for: imageID, size: 150)
                }

                if let artork = character.games.first?.artworks.first, let imageID = artork.imageID {
                    image(for: imageID, size: 150)
                }
            }

            Text(character.character?.name ?? "-")
                .font(.title)

            Text(character.character?.description ?? "-")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .italic()
        }
    }

    @ViewBuilder
    private func errorView(for error: Error) -> some View {
        Text("Error! \(error.localizedDescription)")
            .font(.headline)
            .foregroundStyle(.red)
    }

    private func performSearch() {
        if searchTask?.isCancelled == false {
            searchTask?.cancel()
        }

        searchTask = Task {
            try Task.checkCancellation()
            await viewModel.fetchCharacter(named: searchText, using: dbClient)
        }
    }

    private func image(for resourceID: String, size: CGFloat = 50) -> some View {
        AsyncImage(url: ImageBuilder.imageURL(for: resourceID)) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
        } placeholder: {
            ProgressView()
        }
    }
}

#Preview {
    ContentView()
}
