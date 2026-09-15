//
//  QuranView.swift
//  Adhan
//
//  Created by mohamed on 15/09/2026.
//

import Foundation
import SwiftUI

/// Modèle de données structuré pour représenter une sourate complète
struct SurahModel: Identifiable {
    let id = UUID()
    let number: Int
    let nameFrench: String
    let nameArabic: String
    let translationTitle: String
    let ayahs: [String]
    let frenchTranslation: [String]
}

/// Vue principale listant les sourates disponibles
struct QuranView: View {
    
    // Collection de sourates complètes (ex: Al-Fatihah et Al-Ikhlas, extensibles à volonté)
    let completeSurahs = [
        SurahModel(
            number: 1,
            nameFrench: "Al-Fatihah",
            nameArabic: "الفاتحة",
            translationTitle: "L'ouverture",
            ayahs: [
                "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
                "الرَّحْمَٰنِ الرَّحِيمِ",
                "مَالِكِ يَوْمِ الدِّينِ",
                "إيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
                "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ",
                "صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ"
            ],
            frenchTranslation: [
                "Au nom d'Allah, le Tout Miséricordieux, le Très Miséricordieux.",
                "Louange à Allah, Seigneur de l'univers.",
                "Le Tout Miséricordieux, le Très Miséricordieux,",
                "Maître du Jour de la rétribution.",
                "C'est Toi seul que nous adorons, et c'est Toi seul dont nous implorons secours.",
                "Guide-nous dans le droit chemin,",
                "Le chemin de ceux que Tu as comblés de faveurs, non pas de ceux qui ont encouru Ta colère, ni des égarés."
            ]
        ),
        SurahModel(
            number: 112,
            nameFrench: "Al-Ikhlas",
            nameArabic: "الإخلاص",
            translationTitle: "Le monothéisme pur",
            ayahs: [
                "قُلْ هُوَ اللَّهُ أَحَدٌ",
                "اللَّهُ الصَّمَدُ",
                "لَمْ يَلِدْ وَلَمْ يُولَدْ",
                "وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ"
            ],
            frenchTranslation: [
                "Dis : « Il est Allah, Unique.",
                "Allah, Le Seul à être imploré pour ce que nous désirons.",
                "Il n'a jamais engendré, n'a pas été engendré non plus.",
                "Et nul n'est égal à Lui. »"
            ]
        ),
        SurahModel(
            number: 113,
            nameFrench: "Al-Falaq",
            nameArabic: "الفلق",
            translationTitle: "L'aube naissante",
            ayahs: [
                "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ",
                "مِن شَرِّ مَا خَلَقَ",
                "وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ",
                "وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ",
                "وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ"
            ],
            frenchTranslation: [
                "Dis : « Je cherche protection auprès du Seigneur de l'aube naissante,",
                "contre le mal des êtres qu'Il a créés,",
                "contre le mal de l'obscurité quand elle s'approfondit,",
                "contre le mal de celles qui soufflent sur les nœuds,",
                "et contre le mal de l'envieux quand il envie. »"
            ]
        ),
        SurahModel(
            number: 114,
            nameFrench: "An-Nas",
            nameArabic: "الناس",
            translationTitle: "Les hommes",
            ayahs: [
                "قُلْ أَعُوذُ بِرَبِّ النَّاسِ",
                "مَلِكِ النَّاسِ",
                "إِلَهِ النَّاسِ",
                "مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ",
                "الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ",
                "مِنَ الْجِنَّةِ وَالنَّاسِ"
            ],
            frenchTranslation: [
                "Dis : « Je cherche protection auprès du Seigneur des hommes,",
                "Souverain des hommes,",
                "Dieu des hommes,",
                "contre le mal du mauvais conseiller, furtif,",
                "qui souffle le mal dans les poitrines des hommes,",
                "qu'il soit un djinn ou un homme. »"
            ]
        )
    ]
    
    var body: some View {
        NavigationStack {
            List(completeSurahs) { surah in
                NavigationLink(destination: SurahDetailView(surah: surah)) {
                    HStack(spacing: 16) {
                        // Badge circulaire affichant le numéro de la sourate
                        Text("\(surah.number)")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .frame(width: 38, height: 38)
                            .background(Color.accentColor.opacity(0.12), in: Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(surah.nameFrench)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(surah.translationTitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Nom de la sourate en arabe
                        Text(surah.nameArabic)
                            .font(.system(size: 21, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Le Saint Coran")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Vue détaillée affichant l'intégralité des versets d'une sourate sélectionnée
struct SurahDetailView: View {
    let surah: SurahModel
    
    var body: some View {
        List {
            // En-tête de la sourate
            Section {
                VStack(alignment: .center, spacing: 8) {
                    Text(surah.nameArabic)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(.accentColor)
                    
                    Text("\(surah.nameFrench) — \(surah.translationTitle)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
            }
            
            // Liste verset par verset
            Section {
                ForEach(0..<surah.ayahs.count, id: \.self) { index in
                    VStack(alignment: .trailing, spacing: 12) {
                        // Texte arabe aligné à droite avec police serif élégante
                        Text("\(surah.ayahs[index]) ﴿\(index + 1)﴾")
                            .font(.system(size: 23, weight: .bold, design: .serif))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .foregroundColor(.primary)
                        
                        // Traduction française alignée à gauche
                        Text(surah.frenchTranslation[index])
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Texte et Traduction")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(surah.nameFrench)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    QuranView()
}
