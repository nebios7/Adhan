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
    @State private var breathingText: String = "Inspirez..."
    @State private var timer: Timer? = nil
    
    // Pour l'animation de copie de verset
    @State private var copiedItemId: UUID? = nil
    
    // Collection de versets coraniques de réconfort et de guidance
    let quranicTreasures = [
        QuranicItem(
            category: "Sourate Al-Inshirah",
            arabicText: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا",
            translation: "Certes, avec la difficulty vient la facilité ! Oui, avec la difficulté vient la facilité !",
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
            arabicText: "وَمَنْ يَتَّقِ اللَّهَ يَجْعَل *لَهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لا يَحْتَسِبُ",
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
                                
                                // Bouton pour copier le texte
                                Button(action: {
                                    UIPasteboard.general.string = "\(item.arabicText)\n\(item.translation) (\(item.category): \(item.reference))"
                                    copiedItemId = item.id
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        if copiedItemId == item.id { copiedItemId = nil }
                                    }
                                }) {
                                    Image(systemName: copiedItemId == item.id ? "checkmark.circle.fill" : "doc.on.doc")
                                        .font(.caption)
                                        .foregroundColor(copiedItemId == item.id ? .green : .secondary)
                                }
                                .buttonStyle(.borderless)
                                
                                Text(item.reference)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(item.arabicText)
                                .font(.system(size: 24, weight: .bold, design: .serif))
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
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.15))
                                        .frame(width: 120, height: 120)
                                        .scaleEffect(isBreathingActive ? (breathingText == "Inspirez..." ? 1.4 : 0.9) : 1.0)
                                        .animation(isBreathingActive ? .easeInOut(duration: 5.0).repeatForever(autoreverses: true) : .default, value: isBreathingActive)
                                    
                                    Image(systemName: "wind")
                                        .font(.system(size: 40))
                                        .foregroundColor(.accentColor)
                                        .rotationEffect(.degrees(isBreathingActive ? 360 : 0))
                                        .animation(isBreathingActive ? .linear(duration: 10).repeatForever(autoreverses: false) : .default, value: isBreathingActive)
                                }
                                .frame(height: 160)
                                
                                Text(isBreathingActive ? breathingText : "Appuyez pour commencer")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        Button(action: {
                            toggleBreathing()
                        }) {
                            HStack {
                                Spacer()
                                Text(isBreathingActive ? "Arrêter la pause" : "Démarrer la pause")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isBreathingActive ? .red : .accentColor)
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
    
    // Logique du cycle de respiration
    private func toggleBreathing() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isBreathingActive.toggle()
        
        if isBreathingActive {
            breathingText = "Inspirez..."
            // Alterne toutes les 5 secondes
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation {
                    if breathingText == "Inspirez..." {
                        breathingText = "Expirez..."
                    } else {
                        breathingText = "Inspirez..."
                    }
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
}

#Preview {
    EnhancementsView()
}
