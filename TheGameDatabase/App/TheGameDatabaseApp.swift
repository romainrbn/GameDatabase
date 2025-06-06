//
//  TheGameDatabaseApp.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import SwiftUI

@main
struct TheGameDatabaseApp: App {
    @State private var contentViewModel = ContentViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(contentViewModel)
        }
    }
}
