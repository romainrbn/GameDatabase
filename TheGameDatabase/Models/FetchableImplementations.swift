//
//  FetchableImplementations.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

struct CharacterFetch: Fetchable {
    typealias Model = GameCharacter

    static var endpoint: String { Endpoints.Character.path }
    static var idKeyPath: KeyPath<GameCharacter, Int?> { \.id }

    static func buildQuery(_ builder: QueryBuilder<GameCharacter>) -> QueryBuilder<GameCharacter> {
        return builder.fields { [$0.id, $0.name, $0.description, $0.mugShot, $0.games] }
    }
}

struct MugshotFetch: Fetchable {
    typealias Model = CharacterMugshot

    static var endpoint: String { Endpoints.CharacterMugshot.path }
    static var idKeyPath: KeyPath<CharacterMugshot, Int?> { \.id }

    static func buildQuery(_ builder: QueryBuilder<CharacterMugshot>) -> QueryBuilder<CharacterMugshot> {
        return builder.fields { [$0.id, $0.imageID] }
    }
}

struct GameFetch: Fetchable {
    typealias Model = Game

    static var endpoint: String { Endpoints.Game.path }
    static var idKeyPath: KeyPath<Game, Int?> { \.id }

    static func buildQuery(_ builder: QueryBuilder<Game>) -> QueryBuilder<Game> {
        return builder.fields { [$0.id, $0.name, $0.summary, $0.artworks, $0.cover, $0.firstReleaseDate] }
    }
}

struct ArtworkFetch: Fetchable {
    typealias Model = Artwork

    static var endpoint: String { Endpoints.Artwork.path }
    static var idKeyPath: KeyPath<Artwork, Int?> { \.id }

    static func buildQuery(_ builder: QueryBuilder<Artwork>) -> QueryBuilder<Artwork> {
        return builder.fields { [$0.id, $0.imageID, $0.game] }
    }
}
