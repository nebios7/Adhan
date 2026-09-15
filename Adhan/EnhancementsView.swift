import SwiftUI

/// Modèle de données pour les textes et versets coraniques
struct QuranicItem: Identifiable {
    let id = UUID()
    let category: String
    let arabicText: String
    let translation: String
    let reference: String
}

struct EnhancementsView: View {
    // État pour le module de respiration
    @State private var isBreathingActive: Bool = false
    
    // Collection de versets coraniques de réconfort et de guidance
    let quranicTreasures = [
        QuranicItem(
            category: "Sourate Al-Inshirah",
            arabicText: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا",
            translation: "Certes, avec la difficulté vient la facilité ! Oui, avec la difficulté vient la facilité !",
            reference: "Versets 5-6"
        ),
        QuranicItem(
            category: "Sourate Ar-Ra'd",
            arabicText: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
            translation: "Certes, c'est par l'évocation d'Allah que s'apaisent les cœurs.",
            reference: "Verset 28"
        ),
        QuranicItem(
            category: "Sourate At-Talaq",
            arabicText: "وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لا يَحْتَسِبُ",
            translation: "Et quiconque craint Allah, Il lui donnera une issue favorable et lui accordera Ses dons par des moyens sur lesquels il ne comptait pas.",
            reference: "Versets 2-3"
        ),
        QuranicItem(
            category: "Sourate Al-Baqarah",
            arabicText: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
            translation: "Allah n'impose à aucune âme une charge supérieure à sa capacité.",
            reference: "Verset 286"
        )
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1 : Versets Coraniques de Sérénité
                Section {
                    ForEach(quranicTreasures) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(item.category)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Text(item.reference)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(item.arabicText)
                                .font(.system(size: 21, weight: .bold, design: .serif))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.primary)
                                .padding(.vertical, 4)
                            
                            Text(item.translation)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Versets de Sérénité")
                }
                
                // Section 2 : Pause & Respiration Consciente
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Pause Sérénité", systemImage: "wind")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                            Spacer()
                        }
                        
                        Text("Prenez un moment d'arrêt pour vous recentrer et apaiser votre esprit avant ou après vos prières.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: isBreathingActive ? "circle.inset.filled" : "circle")
                                    .font(.system(size: 44))
                                    .foregroundColor(.accentColor)
                                    .scaleEffect(isBreathingActive ? 1.25 : 1.0)
                                    .animation(isBreathingActive ? .easeInOut(duration: 3.0).repeatForever(autoreverses: true) : .default, value: isBreathingActive)
                                
                                Text(isBreathingActive ? "Inspirez... Expirez..." : "Appuyez pour commencer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        Button(action: {
                            isBreathingActive.toggle()
                        }) {
                            HStack {
                                Spacer()
                                Text(isBreathingActive ? "Arrêter la pause" : "Démarrer la pause")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Espace de Calme")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Spiritualité & Rappels")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    EnhancementsView()
}
