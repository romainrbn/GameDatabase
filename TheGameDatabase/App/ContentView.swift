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

    @State private var error: Error?

    var body: some View {
        VStack {
            if let error {
                Text("Error! \(error.localizedDescription)")
                    .font(.headline)
                    .foregroundStyle(.red)
            } else if let character = viewModel.character {
                VStack {
                    Text(character.name ?? "-")
                    Text("GameIDs: \(character.games ?? [])")
                    Text(character.description ?? "-")
                }
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                try await viewModel.performFetch(with: dbClient)
            } catch {
                self.error = error
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
