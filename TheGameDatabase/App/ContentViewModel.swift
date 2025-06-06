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
    var characterDTO: GameCharacterDTO?
    var isLoading = false
    var error: Error?

    func fetchCharacter(named characterName: String, using client: IGDBClient) async {
        isLoading = true
        error = nil

        do {
            characterDTO = try await GameCharacterDTO.fetch(byName: characterName, using: client)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func fetchCharacter(withID id: Int, using client: IGDBClient) async {
        isLoading = true
        error = nil

        do {
            characterDTO = try await GameCharacterDTO.fetch(byID: id, using: client)
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

extension ContentViewModel {
    var characterName: String {
        characterDTO?.character?.name ?? "Unknown"
    }

    var characterDescription: String {
        characterDTO?.character?.description ?? "No description available"
    }

    var mugshotImageID: String? {
        characterDTO?.mugshot?.imageID
    }

    var gamesWithArtwork: [GameWithArtwork] {
        characterDTO?.games ?? []
    }
}
