//
//  AdhanApp.swift
//  AdhanApp Pro
//
//  Point d'entrée principal de l'application SwiftUI pour iOS.
//

import SwiftUI
import AVFoundation
import StoreKit

@main
struct AdhanApp: App {
    
    init() {
        // Lancement de l'écouteur global des transactions StoreKit 2
        listenForTransactions()
    }

    var body: some Scene {
        WindowGroup {
            // La TabView principale intègre désormais trois onglets autonomes
            TabView {
                // Premier onglet : Accueil et fonctionnalités principales
                ContentView()
                    .tabItem {
                        Label("Accueil", systemImage: "house.fill")
                    }
                
                // Deuxième onglet : Le Coran et ses sourates complètes
                QuranView()
                    .tabItem {
                        Label("Coran", systemImage: "book.fill")
                    }
                
                // Troisième onglet : Le module d'améliorations et de sérénité
                EnhancementsView()
                    .tabItem {
                        Label("Améliorations", systemImage: "sparkles")
                    }
            }
            .accentColor(.blue)
            .onAppear {
                do {
                    try AVAudioSession.sharedInstance().setCategory(
                        .playback,
                        mode: .default,
                        options: [.mixWithOthers]
                    )
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("Erreur initialisation AVAudioSession : \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func listenForTransactions() {
        Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try result.payloadValue
                    await transaction.finish()
                } catch {
                    print("Erreur de mise à jour de transaction StoreKit : \(error)")
                }
            }
        }
    }
}
