//
//  ArgusApp.swift
//  Argus
//
//  Created by Edmund Afunyah on 9/16/26.
//

import SwiftUI

/// Application entry point. Register bundled fonts before any screen is created.
@main
struct ArgusApp: App {
    init() { AppFonts.registerFonts() }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
