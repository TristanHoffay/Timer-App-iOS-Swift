//
//  TimerSwiftApp.swift
//  TimerSwift
//
//  Created by Tristan on 4/21/23.
//

import SwiftUI

@main
struct TimerSwiftApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
