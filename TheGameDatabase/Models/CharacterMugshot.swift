//
//  CharacterMugshot.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation
import Query

@QueryableModel
struct CharacterMugshot: Decodable, Queryable {
    @Field(key: "id")
    var id: Int?

    @Field(key: "image_id")
    var imageID: String?
}
