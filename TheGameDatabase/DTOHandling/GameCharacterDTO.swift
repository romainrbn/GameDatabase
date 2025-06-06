//
//  GameCharacterDTO.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

class GameCharacterDTO: DataTransferObject {
    var character: GameCharacter?
    var mugshot: CharacterMugshot?
    var games: [GameWithArtwork] = []

    private var fetcher: DataFetcher?

    required init() {}

    init(character: GameCharacter) {
        self.character = character
    }

    func fetchDependencies(using client: IGDBClient) async throws {
        let fetcher = DataFetcher(client: client)
        self.fetcher = fetcher

        async let mugshotTask: () = fetchMugshot(fetcher: fetcher)
        async let gamesTask: () = fetchGames(fetcher: fetcher)

        let _ = try await (mugshotTask, gamesTask)
    }

    private func fetchMugshot(fetcher: DataFetcher) async throws {
        guard let mugshotID = character?.mugShot else { return }

        let mugshots = try await fetcher.fetch(FetchRequest(ids: [mugshotID], fetchable: MugshotFetch.self))
        self.mugshot = mugshots.first
    }

    private func fetchGames(fetcher: DataFetcher) async throws {
        guard let gameIDs = character?.games, !gameIDs.isEmpty else { return }

        let games = try await fetcher.fetch(FetchRequest(ids: gameIDs, fetchable: GameFetch.self))

        let allArtworkIDs = games.compactMap { $0.artworks }.flatMap { $0 }

        let artworks: [Artwork]
        if !allArtworkIDs.isEmpty {
            artworks = try await fetcher.fetch(FetchRequest(ids: allArtworkIDs, fetchable: ArtworkFetch.self))
        } else {
            artworks = []
        }

        self.games = games.map { game in
            let gameArtworks = artworks.filter { artwork in
                game.artworks?.contains(artwork.id ?? -1) == true
            }
            return GameWithArtwork(game: game, artworks: gameArtworks)
        }
    }
}

struct GameWithArtwork {
    let game: Game
    let artworks: [Artwork]

    var name: String? { game.name }
    var summary: String? { game.summary }
    var primaryArtwork: Artwork? { artworks.first }
}

extension GameCharacterDTO {
    static func fetch(
        byName name: String,
        using client: IGDBClient
    ) async throws -> GameCharacterDTO? {
        let characters: [GameCharacter] = try await client.query(endpoint: Endpoints.Character.path) { builder in
            builder
                .fields { [$0.name, $0.description, $0.mugShot, $0.games] }
                .where { $0.name == name }
                .limit(1)
        }

        guard let character = characters.first else { return nil }

        let dto = GameCharacterDTO(character: character)
        try await dto.fetchDependencies(using: client)

        return dto
    }

    static func fetch(byID id: Int, using client: IGDBClient) async throws -> GameCharacterDTO? {
        let characters: [GameCharacter] = try await client.query(endpoint: Endpoints.Character.path) { builder in
            builder
                .fields { [$0.name, $0.description, $0.mugShot, $0.games] }
                .where { $0.id == id }
                .limit(1)
        }

        guard let character = characters.first else { return nil }

        let dto = GameCharacterDTO(character: character)
        try await dto.fetchDependencies(using: client)

        return dto
    }
}
