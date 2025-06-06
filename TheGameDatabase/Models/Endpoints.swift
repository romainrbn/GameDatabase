//
//  Endpoints.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

enum Endpoints {
    struct Character {
        static let path = "characters"
        typealias Model = GameCharacter
    }

    struct CharacterMugshot {
        static let path = "character_mug_shots"
        typealias Model = CharacterMugshot
    }

    struct Game {
        static let path = "games"
        typealias Model = Game
    }

    struct Artwork {
        static let path = "artworks"
        typealias Model = Artwork
    }
}
