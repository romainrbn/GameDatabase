//
//  ImageBuilder.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

struct ImageBuilder {
    static func imageURL(for resourceID: String) -> URL {
        return URL(string: "https://images.igdb.com/igdb/image/upload/t_thumb/\(resourceID).jpg")!
    }
}
