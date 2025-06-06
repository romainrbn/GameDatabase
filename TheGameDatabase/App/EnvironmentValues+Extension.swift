//
//  EnvironmentValues+Extension.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var dbClient = IGDBClient(
        apiKey: ProcessInfo.processInfo.environment["SECRET"]!,
        clientId: ProcessInfo.processInfo.environment["CLIENT_ID"]!
    )
}
