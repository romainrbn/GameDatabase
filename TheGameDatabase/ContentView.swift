//
//  ContentView.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.dbClient) var dbClient
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .task {
            do {
                try await performFetch(client: dbClient)
            } catch {
                print("An error occured: \(error)")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
