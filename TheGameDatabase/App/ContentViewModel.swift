//
//  ContentViewModel.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation
import SwiftUI

@Observable
final class ContentViewModel {
    var character: GameCharacter?

    func performFetch(with client: IGDBClient) async throws {
        self.character = try await client.query(endpoint: Endpoints.Character.path) { builder in
            builder
                .fields { [$0.name, $0.description, $0.games ]}
                .where { $0.name == "Arthur Morgan" }
                .limit(1)
        }
        .first
    }
}
