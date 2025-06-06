//
//  GameCharacter.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation
import Query

@QueryableModel
struct GameCharacter: Decodable, Queryable {
    @Field(key: "akas")
    var akas: [String]?

    @Field(key: "checksum")
    var checksum: String?

    @Field(key: "country_name")
    var countryName: String?

    @Field(key: "created_at")
    var createdAt: Int?

    @Field(key: "description")
    var description: String?

    @Field(key: "games")
    var games: [Int]?

    @Field(key: "gender")
    var gender: Int?

    @Field(key: "mug_shot")
    var mugShot: Int?

    @Field(key: "name")
    var name: String?

    @Field(key: "slug")
    var slug: String?

    @Field(key: "species")
    var species: Int?

    @Field(key: "updated_at")
    var updatedAt: Int?

    @Field(key: "url")
    var url: String?
}
