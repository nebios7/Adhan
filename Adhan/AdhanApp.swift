//
//  AdhanApp.swift
//  AdhanApp Pro
//
//  Point d'entrée principal de l'application SwiftUI pour iOS.
//

import SwiftUI
import AVFoundation

@main
struct AdhanApp: App {
    init() {
        // Configuration propre et sécurisée de la session audio
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erreur initialisation AVAudioSession globale: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
