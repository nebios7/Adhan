import SwiftUI
import UIKit
import Foundation
import Combine

// MARK: - Modèle de données
struct QuranicItem: Identifiable, Hashable {
    let id = UUID()
    let category: String
    let arabicText: String
    let translation: String
    let reference: String
}

// MARK: - Persistance des favoris
class FavoritesStore: ObservableObject {
    @Published var favorites: Set<String> = [] {
        didSet { save() }
    }
    private let key = "quranic_favorites"

    init() { load() }

    func toggle(_ item: QuranicItem) {
        let k = keyFor(item)
        if favorites.contains(k) { favorites.remove(k) } else { favorites.insert(k) }
    }

    func isFavorite(_ item: QuranicItem) -> Bool {
        favorites.contains(keyFor(item))
    }

    private func keyFor(_ item: QuranicItem) -> String {
        "\(item.category)|\(item.reference)"
    }

    private func save() {
        UserDefaults.standard.set(Array(favorites), forKey: key)
    }

    private func load() {
        if let arr = UserDefaults.standard.array(forKey: key) as? [String] {
            favorites = Set(arr)
        }
    }
}

// MARK: - Vue principale
struct EnhancementsView: View {
    // État pour le module de respiration
    @State private var isBreathingActive: Bool = false
    @State private var breathingText: String = "Inspirez..."
    @State private var timer: Timer? = nil
    @State private var breathingDuration: Double = 5.0   // Configurable

    // Dhikr / Tasbih
    @State private var dhikrCount: Int = 0
    @State private var selectedDhikr: String = "سُبْحَانَ اللَّه"
    @State private var dhikrHapticEnabled: Bool = true

    // Recherche
    @State private var searchText: String = ""

    // Favoris
    @StateObject private var favorites = FavoritesStore()

    // Copie
    @State private var copiedItemId: UUID? = nil

    // Confirmation reset dhikr
    @State private var showResetAlert: Bool = false

    // MARK: Données
    let quranicTreasures: [QuranicItem] = [
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
            arabicText: "وَمَنْ يَتَّقِ اللَّهَ يَجْعَل لَهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لا يَحْتَسِبُ",
            translation: "Et quiconque craint Allah, Il lui donnera une issue favorable et lui accordera Ses dons par des moyens sur lesquels il ne comptait pas.",
            reference: "Versets 2-3"
        ),
        QuranicItem(
            category: "Sourate Al-Baqarah",
            arabicText: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
            translation: "Allah n'impose à aucune âme une charge supérieure à sa capacité.",
            reference: "Verset 286"
        ),
        QuranicItem(
            category: "Sourate Ash-Sharh",
            arabicText: "وَرَفَعْنَا لَكَ ذِكْرَكَ",
            translation: "Et Nous avons élevé pour toi ta renommée.",
            reference: "Verset 4"
        ),
        QuranicItem(
            category: "Sourate Az-Zumar",
            arabicText: "قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَى أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ",
            translation: "Dis : « Ô Mes serviteurs qui avez commis des excès à votre propre détriment, ne désespérez pas de la miséricorde d'Allah. »",
            reference: "Verset 53"
        )
    ]

    let dhikrOptions: [String] = [
        "سُبْحَانَ اللَّه",
        "الْحَمْدُ لِلَّه",
        "اللَّهُ أَكْبَر",
        "لَا إِلَٰهَ إِلَّا اللَّه",
        "أَسْتَغْفِرُ اللَّه"
    ]

    // MARK: Filtrage
    var filteredTreasures: [QuranicItem] {
        guard !searchText.isEmpty else { return quranicTreasures }
        return quranicTreasures.filter {
            $0.category.localizedCaseInsensitiveContains(searchText) ||
            $0.translation.localizedCaseInsensitiveContains(searchText) ||
            $0.reference.localizedCaseInsensitiveContains(searchText) ||
            $0.arabicText.contains(searchText)
        }
    }

    /// Verset "du jour" déterministe basé sur le jour de l'année
    var verseOfTheDay: QuranicItem {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return quranicTreasures[day % quranicTreasures.count]
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            List {
                // MARK: Verset du jour
                Section {
                    VerseOfDayCard(item: verseOfTheDay)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                // MARK: Versets
                Section {
                    ForEach(filteredTreasures) { item in
                        VerseRow(
                            item: item,
                            isCopied: copiedItemId == item.id,
                            isFavorite: favorites.isFavorite(item),
                            onCopy: { copy(item) },
                            onFavorite: {
                                withAnimation { favorites.toggle(item) }
                                haptic(.light)
                            },
                            onShare: { share(item) }
                        )
                    }
                    if filteredTreasures.isEmpty {
                        Text("Aucun verset ne correspond à votre recherche.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Versets de Sérénité")
                }

                // MARK: Dhikr
                Section {
                    DhikrView(
                        count: $dhikrCount,
                        selected: $selectedDhikr,
                        options: dhikrOptions,
                        hapticEnabled: dhikrHapticEnabled,
                        onReset: { showResetAlert = true }
                    )
                } header: {
                    Text("Dhikr — Compteur")
                } footer: {
                    Text("Le compteur se réinitialise automatiquement à 33, 99 ou à la valeur de votre choix.")
                        .font(.caption2)
                }

                // MARK: Respiration
                Section {
                    BreathingView(
                        isActive: $isBreathingActive,
                        text: $breathingText,
                        duration: $breathingDuration,
                        onToggle: toggleBreathing
                    )
                } header: {
                    Text("Espace de Calme")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Spiritualité & Rappels")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Rechercher un verset…")
            .alert("Réinitialiser le compteur ?", isPresented: $showResetAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Réinitialiser", role: .destructive) {
                    withAnimation { dhikrCount = 0 }
                    haptic(.medium)
                }
            }
        }
    }

    // MARK: Actions
    private func copy(_ item: QuranicItem) {
        UIPasteboard.general.string = "\(item.arabicText)\n\(item.translation) (\(item.category): \(item.reference))"
        copiedItemId = item.id
        haptic(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedItemId == item.id { copiedItemId = nil }
        }
    }

    private func share(_ item: QuranicItem) {
        let text = "\(item.arabicText)\n\n\(item.translation)\n\n— \(item.category), \(item.reference)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: Logique du cycle de respiration
    private func toggleBreathing() {
        haptic(.medium)
        isBreathingActive.toggle()

        if isBreathingActive {
            breathingText = "Inspirez..."
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: breathingDuration, repeats: true) { _ in
                haptic(.light)
                withAnimation {
                    breathingText = (breathingText == "Inspirez...") ? "Expirez..." : "Inspirez..."
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - Carte "Verset du jour"
struct VerseOfDayCard: View {
    let item: QuranicItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Verset du jour", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundColor(.accentColor)
                Spacer()
                Text(item.reference)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(item.arabicText)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.primary)

            Text(item.translation)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Ligne de verset
struct VerseRow: View {
    let item: QuranicItem
    let isCopied: Bool
    let isFavorite: Bool
    let onCopy: () -> Void
    let onFavorite: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)

                Spacer()

                // Favori
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundColor(isFavorite ? .pink : .secondary)
                }
                .buttonStyle(.borderless)

                // Partage
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)

                // Copie
                Button(action: onCopy) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(isCopied ? .green : .secondary)
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
                .accessibilityLabel("Texte arabe")

            Text(item.translation)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button { onCopy() } label: { Label("Copier", systemImage: "doc.on.doc") }
            Button { onShare() } label: { Label("Partager", systemImage: "square.and.arrow.up") }
            Button { onFavorite() } label: {
                Label(isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                      systemImage: isFavorite ? "heart.slash" : "heart")
            }
        }
    }
}

// MARK: - Vue Dhikr
struct DhikrView: View {
    @Binding var count: Int
    @Binding var selected: String
    let options: [String]
    let hapticEnabled: Bool
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Sélecteur de dhikr
            Picker("Dhikr", selection: $selected) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .font(.headline)

            // Compteur
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Text("\(count)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: count)
                    Text("cliquez sur le cercle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Bouton tap
            HStack {
                Spacer()
                Button {
                    count += 1
                    if hapticEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Circle()
                            .stroke(Color.accentColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 120, height: 120)
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Incrémenter le compteur de dhikr")
                Spacer()
            }

            // Actions
            HStack {
                Button(role: .destructive, action: onReset) {
                    Label("Réinitialiser", systemImage: "arrow.counterclockwise")
                        .font(.footnote)
                }
                Spacer()
                Button {
                    count = max(0, count - 1)
                    if hapticEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
                } label: {
                    Label("-1", systemImage: "minus.circle")
                        .font(.footnote)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Vue Respiration
struct BreathingView: View {
    @Binding var isActive: Bool
    @Binding var text: String
    @Binding var duration: Double
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pause Sérénité", systemImage: "wind")
                .font(.headline)
                .foregroundColor(.accentColor)

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
                            .scaleEffect(isActive ? (text == "Inspirez..." ? 1.4 : 0.9) : 1.0)
                            .animation(isActive ? .easeInOut(duration: duration).repeatForever(autoreverses: true) : .default, value: isActive)

                        Image(systemName: "wind")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                            .rotationEffect(.degrees(isActive ? 360 : 0))
                            .animation(isActive ? .linear(duration: duration * 2).repeatForever(autoreverses: false) : .default, value: isActive)
                    }
                    .frame(height: 160)

                    Text(isActive ? text : "Appuyez pour commencer")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .contentTransition(.opacity)
                }
                Spacer()
            }
            .padding(.vertical, 8)

            // Durée configurable
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Durée d'un cycle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(duration))s")
                        .font(.caption.bold())
                        .foregroundColor(.accentColor)
                }
                Slider(value: $duration, in: 3...10, step: 1)
                    .tint(.accentColor)
                    .disabled(isActive)
            }

            Button(action: onToggle) {
                HStack {
                    Spacer()
                    Label(isActive ? "Arrêter la pause" : "Démarrer la pause",
                          systemImage: isActive ? "stop.fill" : "play.fill")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isActive ? .red : .accentColor)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    EnhancementsView()
}
