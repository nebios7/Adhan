//
//  ContentView.swift
//  Adhan
//
//  Fichier UNIQUE et autonome contenant : modèles, enums, managers,
//  ViewModel, StoreKit et toutes les vues SwiftUI de l'application.
//  Cible : iOS 17 à iOS 26+ — Conforme Swift 6 Concurrency & Zero Warning.
//

import SwiftUI
import AVFoundation
import AudioToolbox
import CoreLocation
import UserNotifications
import Combine
import EventKit
import StoreKit
import MapKit
import WebKit

// MARK: - ============================================================
// MARK: - EXTENSIONS COULEURS
// MARK: - ============================================================

extension Color {
    static let adhanPrimary = Color(red: 0.05, green: 0.45, blue: 0.35)
    static let adhanGold = Color(red: 0.78, green: 0.62, blue: 0.20)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let appBackground = Color(.systemGroupedBackground)
    static let progressTint = Color(red: 0.10, green: 0.55, blue: 0.45)
    static let softAlert = Color(red: 0.85, green: 0.45, blue: 0.25)
}

// MARK: - ============================================================
// MARK: - ENUMS
// MARK: - ============================================================

enum CalculationMethod: String, CaseIterable, Identifiable, Codable {
    case grandeMosqueeParis   = "Grande Mosquée de Paris"
    case mwl                  = "Muslim World League (MWL)"
    case ummAlQura            = "Oum Al-Qura (Mecque)"
    case uoif                 = "UOIF (12°)"
    case isna                 = "ISNA"
    case egypt                = "Égypte (Survey)"
    case custom               = "Angles personnalisés"

    var id: String { rawValue }

    var fajrAngle: Double {
        switch self {
        case .grandeMosqueeParis: return 18.0
        case .mwl:                return 18.0
        case .ummAlQura:          return 18.5
        case .uoif:               return 12.0
        case .isna:               return 15.0
        case .egypt:              return 19.5
        case .custom:             return 18.0
        }
    }

    var ishaAngle: Double {
        switch self {
        case .grandeMosqueeParis: return 17.0
        case .mwl:                return 17.0
        case .ummAlQura:          return 0.0
        case .uoif:               return 12.0
        case .isna:               return 15.0
        case .egypt:              return 17.5
        case .custom:             return 17.0
        }
    }

    var usesFixedIshaOffset: Bool { self == .ummAlQura }

    func ishaFixedMinutesAfterMaghrib(isRamadan: Bool) -> Double {
        isRamadan ? 120.0 : 90.0
    }
}

enum AsrJuristicMethod: String, Codable {
    case standard = "Standard (Chafi'i/Maliki/Hanbali)"

    var shadowFactor: Double {
        switch self {
        case .standard: return 1.0
        }
    }
}

enum PrayerType: String, CaseIterable, Identifiable, Codable {
    case fajr    = "Fajr"
    case sunrise = "Chourouk"
    case dhuhr   = "Dhuhr"
    case asr     = "Asr"
    case maghrib = "Maghrib"
    case isha    = "Isha"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .fajr:    return "sunrise.fill"
        case .sunrise: return "sun.horizon.fill"
        case .dhuhr:   return "sun.max.fill"
        case .asr:     return "sun.min.fill"
        case .maghrib: return "sunset.fill"
        case .isha:    return "moon.stars.fill"
        }
    }

    var isActualPrayer: Bool { self != .sunrise }
}

enum NotificationMode: String, CaseIterable, Identifiable, Codable {
    case adhan    = "Adhan"
    case beep     = "Bip"
    case vibrate  = "Vibreur"
    case silent   = "Silencieux"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .adhan:   return "speaker.wave.3.fill"
        case .beep:    return "bell.fill"
        case .vibrate: return "iphone.radiowaves.left.and.right"
        case .silent:  return "bell.slash.fill"
        }
    }
}

enum ReminderSoundType: String, CaseIterable, Identifiable, Codable {
    case defaultSound = "Son par défaut"
    case chime        = "Carillon doux"
    case none         = "Aucun (silencieux)"

    var id: String { rawValue }
}

enum AdhanPlaybackDuration: String, CaseIterable, Identifiable, Codable {
    case full     = "Complet"
    case sec30    = "30 secondes"
    case min1     = "1 minute"
    case min2     = "2 minutes"

    var id: String { rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .full:  return nil
        case .sec30: return 30
        case .min1:  return 60
        case .min2:  return 120
        }
    }
}

enum FastingCategory: String, CaseIterable, Identifiable, Codable {
    case ramadan        = "Ramadan"
    case mondayThursday = "Lundi / Jeudi"
    case whiteDays      = "Jours blancs (13-14-15 du mois lunaire)"
    case none           = "Aucun jeûne aujourd'hui"

    var id: String { rawValue }
}

enum FlashPattern: String, CaseIterable, Identifiable, Codable {
    case slow   = "Lent"
    case fast   = "Rapide"
    case pulsed = "Pulsé"

    var id: String { rawValue }

    var toggleInterval: TimeInterval {
        switch self {
        case .slow:   return 0.8
        case .fast:   return 0.2
        case .pulsed: return 0.4
        }
    }
}

enum AppColorScheme: String, CaseIterable, Identifiable, Codable {
    case automatic = "Automatique"
    case light     = "Clair"
    case dark      = "Sombre"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light:     return .light
        case .dark:      return .dark
        }
    }
}

enum NotificationBannerStyle: String, CaseIterable, Identifiable, Codable {
    case persistent = "Persistante"
    case temporary  = "Temporaire"
    case critical   = "Critique"

    var id: String { rawValue }

    @available(iOS 15.0, *)
    var interruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .persistent: return .timeSensitive
        case .temporary:  return .active
        case .critical:   return .critical
        }
    }
}

// MARK: - ============================================================
// MARK: - STRUCTS (MODÈLES DE DONNÉES)
// MARK: - ============================================================

struct PrayerItem: Identifiable, Codable, Equatable {
    var id: String { type.rawValue }
    let type: PrayerType
    var time: Date
    var notificationMode: NotificationMode = .adhan
    var manualFixedTime: Date? = nil
    var manualOffsetMinutes: Int = 0
    var assignedAudioTrackID: UUID? = nil
    var customReminderMinutes: Int? = nil

    var effectiveTime: Date {
        if let fixed = manualFixedTime { return fixed }
        return Calendar.current.date(byAdding: .minute, value: manualOffsetMinutes, to: time) ?? time
    }
}

struct CityPreset: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    init(id: UUID = UUID(), name: String, country: String, latitude: Double, longitude: Double, timeZoneIdentifier: String) {
        self.id = id
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    static let defaults: [CityPreset] = [
        CityPreset(name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522, timeZoneIdentifier: "Europe/Paris"),
        CityPreset(name: "Lyon", country: "France", latitude: 45.7640, longitude: 4.8357, timeZoneIdentifier: "Europe/Paris"),
        CityPreset(name: "Marseille", country: "France", latitude: 43.2965, longitude: 5.3698, timeZoneIdentifier: "Europe/Paris"),
        CityPreset(name: "Bruxelles", country: "Belgique", latitude: 50.8503, longitude: 4.3517, timeZoneIdentifier: "Europe/Brussels"),
        CityPreset(name: "Batna", country: "Algérie", latitude: 35.5559, longitude: 6.1741, timeZoneIdentifier: "Africa/Algiers"),
        CityPreset(name: "Alger", country: "Algérie", latitude: 36.7538, longitude: 3.0588, timeZoneIdentifier: "Africa/Algiers"),
        CityPreset(name: "La Mecque", country: "Arabie Saoudite", latitude: 21.4225, longitude: 39.8262, timeZoneIdentifier: "Asia/Riyadh"),
        CityPreset(name: "Casablanca", country: "Maroc", latitude: 33.5731, longitude: -7.5898, timeZoneIdentifier: "Africa/Casablanca"),
        CityPreset(name: "Tunis", country: "Tunisie", latitude: 36.8065, longitude: 10.1815, timeZoneIdentifier: "Africa/Tunis"),
    ]
}

struct AudioTrack: Identifiable, Codable, Equatable {
    var id = UUID()
    var displayName: String
    var fileName: String
    var isBuiltIn: Bool = false
    var durationSeconds: TimeInterval? = nil
}

struct OnlineAdhanPreset: Identifiable, Codable, Equatable {
    var id = UUID()
    var displayName: String
    var reciterName: String
    var remoteURL: URL
    var fileSizeApprox: String = "~2-4 Mo"
}

struct NawafilReminder: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var time: Date
    var repeatingWeekdays: Set<Int> = Set(1...7)
    var isEnabled: Bool = true
    var note: String = ""
}

struct IslamicEvent: Identifiable {
    var id: String { name }
    let name: String
    let hijriMonth: Int
    let hijriDay: Int

    static let all: [IslamicEvent] = [
        IslamicEvent(name: "Nouvel an hégirien", hijriMonth: 1, hijriDay: 1),
        IslamicEvent(name: "Achoura", hijriMonth: 1, hijriDay: 10),
        IslamicEvent(name: "Mawlid (naissance du Prophète ﷺ)", hijriMonth: 3, hijriDay: 12),
        IslamicEvent(name: "Isra et Mi'raj", hijriMonth: 7, hijriDay: 27),
        IslamicEvent(name: "Début du Ramadan", hijriMonth: 9, hijriDay: 1),
        IslamicEvent(name: "Laylat al-Qadr (27e nuit, estimée)", hijriMonth: 9, hijriDay: 27),
        IslamicEvent(name: "Eid al-Fitr", hijriMonth: 10, hijriDay: 1),
        IslamicEvent(name: "Jour d'Arafat", hijriMonth: 12, hijriDay: 9),
        IslamicEvent(name: "Eid al-Adha", hijriMonth: 12, hijriDay: 10),
    ]

    func nextOccurrence(from referenceDate: Date = Date()) -> Date? {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let currentHijriYear = hijriCalendar.component(.year, from: referenceDate)

        for yearOffset in 0...1 {
            var components = DateComponents()
            components.year = currentHijriYear + yearOffset
            components.month = hijriMonth
            components.day = hijriDay
            components.calendar = hijriCalendar
            if let candidate = hijriCalendar.date(from: components), candidate >= Calendar.current.startOfDay(for: referenceDate) {
                return candidate
            }
        }
        return nil
    }
}

struct FastingReminder: Identifiable, Codable, Equatable {
    var id = UUID()
    var category: FastingCategory
    var isEnabled: Bool = true
    var reminderMinutesBeforeImsak: Int = 60
    var eventTitle: String = ""
    var soundType: ReminderSoundType = .defaultSound
    var customSoundTrackID: UUID? = nil
}

struct MemoNote: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var content: String
    var createdAt: Date = Date()
}

// MARK: - PrayerSettings

struct PrayerSettings: Codable, Equatable {
    var calculationMethod: CalculationMethod
    var asrMethod: AsrJuristicMethod
    var customFajrAngle: Double
    var customIshaAngle: Double
    var hijriDayOffset: Int
    var defaultNotificationMode: NotificationMode
    var reminderMinutesBeforePrayer: Int
    var fajrProgressiveAlarmEnabled: Bool
    var fajrProgressiveAlarmMinutesBefore: Int
    var fridayKahfReminderEnabled: Bool
    var fastingEveReminderEnabled: Bool
    var respectDoNotDisturb: Bool
    var globalPlaybackDuration: AdhanPlaybackDuration
    var adhanVolume: Double
    var selectedCity: CityPreset
    var defaultAudioTrackID: UUID?

    var followCurrentLocation: Bool
    var preferredColorScheme: AppColorScheme
    var exportToCalendarEnabled: Bool
    var enabledIslamicEventReminders: [String: Bool]
    var reminderSoundTrackID: UUID?
    var forceAudioEvenInSilentMode: Bool

    // RAPPEL VISUEL (FLASH)
    var flashEnabled: Bool
    var flashDuration: Double
    var flashPattern: FlashPattern

    // NOTIFICATIONS AVANCÉES
    var notificationSoundEnabled: Bool
    var notificationBannerStyle: NotificationBannerStyle
    var notificationPreciseTime: Bool

    // MODES DE NOTIFICATION INDIVIDUELS PAR PRIÈRE
    var prayerNotificationModes: [String: NotificationMode]

    init(
        calculationMethod: CalculationMethod = .mwl,
        asrMethod: AsrJuristicMethod = .standard,
        customFajrAngle: Double = 18.0,
        customIshaAngle: Double = 17.0,
        hijriDayOffset: Int = 0,
        defaultNotificationMode: NotificationMode = .adhan,
        reminderMinutesBeforePrayer: Int = 10,
        fajrProgressiveAlarmEnabled: Bool = true,
        fajrProgressiveAlarmMinutesBefore: Int = 20,
        fridayKahfReminderEnabled: Bool = true,
        fastingEveReminderEnabled: Bool = true,
        respectDoNotDisturb: Bool = true,
        globalPlaybackDuration: AdhanPlaybackDuration = .full,
        adhanVolume: Double = 1.0,
        selectedCity: CityPreset = CityPreset.defaults[0],
        defaultAudioTrackID: UUID? = nil,
        followCurrentLocation: Bool = false,
        preferredColorScheme: AppColorScheme = .automatic,
        exportToCalendarEnabled: Bool = false,
        enabledIslamicEventReminders: [String: Bool] = [:],
        reminderSoundTrackID: UUID? = nil,
        forceAudioEvenInSilentMode: Bool = false,
        flashEnabled: Bool = false,
        flashDuration: Double = 5.0,
        flashPattern: FlashPattern = .slow,
        notificationSoundEnabled: Bool = true,
        notificationBannerStyle: NotificationBannerStyle = .persistent,
        notificationPreciseTime: Bool = true,
        prayerNotificationModes: [String: NotificationMode] = [:]
    ) {
        self.calculationMethod = calculationMethod
        self.asrMethod = asrMethod
        self.customFajrAngle = customFajrAngle
        self.customIshaAngle = customIshaAngle
        self.hijriDayOffset = hijriDayOffset
        self.defaultNotificationMode = defaultNotificationMode
        self.reminderMinutesBeforePrayer = reminderMinutesBeforePrayer
        self.fajrProgressiveAlarmEnabled = fajrProgressiveAlarmEnabled
        self.fajrProgressiveAlarmMinutesBefore = fajrProgressiveAlarmMinutesBefore
        self.fridayKahfReminderEnabled = fridayKahfReminderEnabled
        self.fastingEveReminderEnabled = fastingEveReminderEnabled
        self.respectDoNotDisturb = respectDoNotDisturb
        self.globalPlaybackDuration = globalPlaybackDuration
        self.adhanVolume = adhanVolume
        self.selectedCity = selectedCity
        self.defaultAudioTrackID = defaultAudioTrackID
        self.followCurrentLocation = followCurrentLocation
        self.preferredColorScheme = preferredColorScheme
        self.exportToCalendarEnabled = exportToCalendarEnabled
        self.enabledIslamicEventReminders = enabledIslamicEventReminders
        self.reminderSoundTrackID = reminderSoundTrackID
        self.forceAudioEvenInSilentMode = forceAudioEvenInSilentMode
        self.flashEnabled = flashEnabled
        self.flashDuration = flashDuration
        self.flashPattern = flashPattern
        self.notificationSoundEnabled = notificationSoundEnabled
        self.notificationBannerStyle = notificationBannerStyle
        self.notificationPreciseTime = notificationPreciseTime
        self.prayerNotificationModes = prayerNotificationModes
    }
}

// MARK: - ============================================================
// MARK: - STOREKIT MANAGER
// MARK: - ============================================================

@MainActor
final class StoreKitManager: ObservableObject {
    @Published var purchaseStateMessage: String = ""
    @Published var isPurchasing: Bool = false
    @Published var availableProducts: [Product] = []
    @Published var isLoadingProducts: Bool = true
    @Published var loadError: String? = nil

    let productIdentifiers = [
        "mlseclab.Adhan.tip.small.v2",
        "mlseclab.Adhan.tip.medium.v2",
        "mlseclab.Adhan.tip.large.v2"
    ]

    init() {
        Task { await loadProducts() }
    }

    func loadProducts() async {
        isLoadingProducts = true
        loadError = nil
        do {
            let products = try await Product.products(for: productIdentifiers)
            availableProducts = products.sorted { $0.price < $1.price }
            if products.isEmpty {
                loadError = "Aucun produit configuré pour le moment."
            }
        } catch {
            loadError = "Impossible de charger les options de soutien : \(error.localizedDescription)"
        }
        isLoadingProducts = false
    }

    func buy(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseStateMessage = "Qu'Allah vous récompense pour votre soutien !"
                case .unverified:
                    purchaseStateMessage = "Transaction non vérifiée par Apple — aucun montant n'a été confirmé."
                }
            case .userCancelled:
                break
            case .pending:
                purchaseStateMessage = "Transaction en attente d'approbation (contrôle parental ou autre)."
            @unknown default:
                break
            }
        } catch {
            purchaseStateMessage = "La transaction n'a pas pu aboutir : \(error.localizedDescription)"
        }
    }
}

// MARK: - ============================================================
// MARK: - CALCULATEUR ASTRONOMIQUE
// MARK: - ============================================================

final class AstronomicalPrayerCalculator {

    struct Input {
        let date: Date
        let latitude: Double
        let longitude: Double
        let timeZone: TimeZone
        let fajrAngle: Double
        let ishaAngle: Double
        let usesFixedIshaOffset: Bool
        let ishaFixedMinutesAfterMaghrib: Double
        let asrShadowFactor: Double
    }

    struct Output {
        let imsak: Date
        let fajr: Date
        let sunrise: Date
        let dhuhr: Date
        let asr: Date
        let maghrib: Date
        let isha: Date
        let iftar: Date
    }

    func calculate(_ input: Input) -> Output? {
        let calendar = Calendar(identifier: .gregorian)
        guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: input.date) else { return nil }

        let latRad = input.latitude * .pi / 180.0
        let gamma = 2.0 * .pi / 365.0 * (Double(dayOfYear) - 1.0)
        let eqTime = 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma)
                                - 0.014615 * cos(2 * gamma) - 0.040849 * sin(2 * gamma))
        let decl = 0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma)
                   - 0.006758 * cos(2 * gamma) + 0.000907 * sin(2 * gamma)
                   - 0.002697 * cos(3 * gamma) + 0.00148 * sin(3 * gamma)

        func hourAngle(forAngle angleDeg: Double) -> Double? {
            let angleRad = -angleDeg * .pi / 180.0
            let cosH = (sin(angleRad) - sin(latRad) * sin(decl)) / (cos(latRad) * cos(decl))
            guard cosH >= -1, cosH <= 1 else { return nil }
            return acos(cosH) * 180.0 / .pi
        }

        func asrHourAngle() -> Double? {
            let shadowAngle = atan(1.0 / (input.asrShadowFactor + tan(abs(latRad - decl))))
            let shadowAngleDeg = shadowAngle * 180.0 / .pi
            return hourAngle(forAngle: -shadowAngleDeg)
        }

        let utcOffsetHours = Double(input.timeZone.secondsFromGMT(for: input.date)) / 3600.0
        let solarNoonUTCMinutes = 720.0 - 4.0 * input.longitude - eqTime
        let dhuhrMinutes = solarNoonUTCMinutes + utcOffsetHours * 60.0

        func timeFromMinutes(_ minutesFromMidnight: Double) -> Date {
            let startOfDay = calendar.startOfDay(for: input.date)
            return startOfDay.addingTimeInterval(minutesFromMidnight * 60.0)
        }

        guard let fajrHA = hourAngle(forAngle: input.fajrAngle),
              let sunriseHA = hourAngle(forAngle: 0.833),
              let asrHA = asrHourAngle() else {
            return nil
        }

        let fajrMinutes = dhuhrMinutes - fajrHA * 4.0
        let sunriseMinutes = dhuhrMinutes - sunriseHA * 4.0
        let asrMinutes = dhuhrMinutes + asrHA * 4.0
        let maghribMinutes = dhuhrMinutes + sunriseHA * 4.0

        var ishaMinutes: Double
        if input.usesFixedIshaOffset {
            ishaMinutes = maghribMinutes + input.ishaFixedMinutesAfterMaghrib
        } else if let ishaHA = hourAngle(forAngle: input.ishaAngle) {
            ishaMinutes = dhuhrMinutes + ishaHA * 4.0
        } else {
            ishaMinutes = maghribMinutes + 90.0
        }

        let imsakMinutes = fajrMinutes - 10.0

        return Output(
            imsak: timeFromMinutes(imsakMinutes),
            fajr: timeFromMinutes(fajrMinutes),
            sunrise: timeFromMinutes(sunriseMinutes),
            dhuhr: timeFromMinutes(dhuhrMinutes),
            asr: timeFromMinutes(asrMinutes),
            maghrib: timeFromMinutes(maghribMinutes),
            isha: timeFromMinutes(ishaMinutes),
            iftar: timeFromMinutes(maghribMinutes)
        )
    }

    static func qiblaBearing(fromLat lat: Double, lon: Double) -> Double {
        let kaabaLat = 21.4225 * .pi / 180.0
        let kaabaLon = 39.8262 * .pi / 180.0
        let latRad = lat * .pi / 180.0
        let lonRad = lon * .pi / 180.0
        let deltaLon = kaabaLon - lonRad
        let y = sin(deltaLon) * cos(kaabaLat)
        let x = cos(latRad) * sin(kaabaLat) - sin(latRad) * cos(kaabaLat) * cos(deltaLon)
        var bearing = atan2(y, x) * 180.0 / .pi
        if bearing < 0 { bearing += 360.0 }
        return bearing
    }

    static func distanceToMecca(fromLat lat: Double, lon: Double) -> Double {
        let earthRadiusKm = 6371.0
        let kaabaLat = 21.4225 * .pi / 180.0
        let kaabaLon = 39.8262 * .pi / 180.0
        let latRad = lat * .pi / 180.0
        let lonRad = lon * .pi / 180.0
        let dLat = kaabaLat - latRad
        let dLon = kaabaLon - lonRad
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(latRad) * cos(kaabaLat) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }
}

// MARK: - ============================================================
// MARK: - GESTIONNAIRE LOCALISATION & BOUSSOLE
// MARK: - ============================================================

@MainActor
final class LocationAndCompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var headingDegrees: Double = 0.0
    @Published var smoothedHeadingDegrees: Double = 0.0
    @Published var headingAccuracy: Double = -1.0
    @Published var isHeadingAvailable: Bool = false
    @Published var lastErrorMessage: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1.0
        isHeadingAvailable = CLLocationManager.headingAvailable()
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            isHeadingAvailable = true
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.currentLocation = locations.last
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let raw = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        guard raw >= 0 else { return }

        Task { @MainActor in
            self.headingDegrees = raw
            let alpha = 0.15
            self.smoothedHeadingDegrees = self.smoothedHeadingDegrees * (1 - alpha) + raw * alpha
            self.headingAccuracy = newHeading.headingAccuracy
        }
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - ============================================================
// MARK: - FLASH LIGHT MANAGER
// MARK: - ============================================================

final class FlashLightManager {
    private var timer: Timer?
    private(set) var isActive: Bool = false

    func flash(duration: TimeInterval, pattern: FlashPattern) {
        stop()
        guard isAvailable() else { return }

        let interval = pattern.toggleInterval
        var isOn = false
        var elapsed: TimeInterval = 0
        isActive = true

        let localTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] t in
            guard let self, self.isActive else {
                t.invalidate()
                self?.forceOff()
                return
            }
            isOn.toggle()
            self.setTorch(on: isOn)
            elapsed += interval
            if elapsed >= duration {
                self.stop()
            }
        }
        RunLoop.main.add(localTimer, forMode: .common)
        timer = localTimer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isActive = false
        forceOff()
    }

    func isAvailable() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.hasTorch && device.isTorchAvailable
    }

    private func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch, device.isTorchAvailable else { return }
        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: Float(1.0))
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            // Ignoré
        }
    }

    private func forceOff() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {}
    }
}

// MARK: - ============================================================
// MARK: - AUDIO PLAYER MANAGER
// MARK: - ============================================================

final class AudioPlayerManager: NSObject, ObservableObject {

    @Published var isPlayingFullAdhan: Bool = false
    @Published var library: [AudioTrack] = []
    @Published var onlinePresets: [OnlineAdhanPreset] = []
    @Published var downloadProgress: [UUID: Double] = [:]
    @Published var lastPlaybackError: String? = nil

    let flashManager = FlashLightManager()
    private var player: AVAudioPlayer?

    var isFlashCurrentlyActive: Bool { flashManager.isActive }

    private let documentsAdhanFolder: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("AdhanLibrary", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()

    override init() {
        super.init()
        loadLibraryFromDisk()
        seedBuiltInTrackIfNeeded()
    }

    func resolvedURL(for track: AudioTrack) -> URL? {
        if track.isBuiltIn {
            let name = (track.fileName as NSString).deletingPathExtension
            let ext = (track.fileName as NSString).pathExtension
            guard let bundleURL = Bundle.main.url(forResource: name, withExtension: ext) else {
                lastPlaybackError = "Fichier « \(track.fileName) » introuvable dans le Bundle."
                return nil
            }
            return bundleURL
        } else {
            let url = documentsAdhanFolder.appendingPathComponent(track.fileName)
            guard FileManager.default.fileExists(atPath: url.path) else {
                lastPlaybackError = "Fichier « \(track.fileName) » introuvable dans la bibliothèque locale."
                return nil
            }
            return url
        }
    }

    private func configurePlaybackSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erreur configuration AVAudioSession : \(error.localizedDescription)")
        }
    }

    func playFullAdhan(from url: URL, maxDuration: AdhanPlaybackDuration, volume: Double = 1.0) {
        configurePlaybackSession()
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = Float(volume)
            player?.prepareToPlay()
            player?.play()
            isPlayingFullAdhan = true

            if let seconds = maxDuration.seconds {
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
                    self?.fadeOutAndStop()
                }
            }
        } catch {
            lastPlaybackError = "Impossible de lire ce fichier audio : \(error.localizedDescription)"
            isPlayingFullAdhan = false
        }
    }

    func testPlay(track: AudioTrack, volume: Double = 1.0) {
        lastPlaybackError = nil
        guard let url = resolvedURL(for: track) else { return }
        playFullAdhan(from: url, maxDuration: .full, volume: volume)
    }

    func stopPlayback() {
        player?.stop()
        isPlayingFullAdhan = false
        flashManager.stop()
    }

    func testBeep() {
        AudioServicesPlaySystemSound(1005)
    }

    private func fadeOutAndStop() {
        guard let player else { return }
        let fadeSteps = 10
        let fadeDuration = 0.5
        for step in 0...fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * (fadeDuration / Double(fadeSteps))) {
                player.volume = Float(fadeSteps - step) / Float(fadeSteps)
                if step == fadeSteps {
                    player.stop()
                    self.isPlayingFullAdhan = false
                    self.flashManager.stop()
                }
            }
        }
    }

    private func seedBuiltInTrackIfNeeded() {
        guard library.isEmpty else { return }
        library.append(AudioTrack(displayName: "Adhan par défaut", fileName: "Adan.mp3", isBuiltIn: true))
    }

    func importAudioFile(from sourceURL: URL, displayName: String) {
        let didStartAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if didStartAccess { sourceURL.stopAccessingSecurityScopedResource() } }

        let destinationFileName = "\(UUID().uuidString).\(sourceURL.pathExtension)"
        let destinationURL = documentsAdhanFolder.appendingPathComponent(destinationFileName)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            let track = AudioTrack(displayName: displayName, fileName: destinationFileName, isBuiltIn: false)
            library.append(track)
            saveLibraryToDisk()
        } catch {
            print("Erreur import audio : \(error.localizedDescription)")
        }
    }

    func downloadOnlinePreset(_ preset: OnlineAdhanPreset, completion: @escaping (Bool) -> Void) {
        let task = URLSession.shared.downloadTask(with: preset.remoteURL) { [weak self] tempURL, _, error in
            guard let self, let tempURL, error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            let destinationFileName = "\(preset.id.uuidString).m4a"
            let destinationURL = self.documentsAdhanFolder.appendingPathComponent(destinationFileName)
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                let track = AudioTrack(displayName: preset.displayName, fileName: destinationFileName, isBuiltIn: false)
                DispatchQueue.main.async {
                    self.library.append(track)
                    self.saveLibraryToDisk()
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
        task.resume()
    }

    private func saveLibraryToDisk() {
        if let data = try? JSONEncoder().encode(library) {
            UserDefaults.standard.set(data, forKey: "audioLibrary")
        }
    }

    func deleteTrack(_ track: AudioTrack) {
        guard !track.isBuiltIn else { return }
        let fileURL = documentsAdhanFolder.appendingPathComponent(track.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        library.removeAll { $0.id == track.id }
        saveLibraryToDisk()
    }

    func renameTrack(_ track: AudioTrack, to newName: String) {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty,
              let index = library.firstIndex(where: { $0.id == track.id }) else { return }
        library[index].displayName = newName
        saveLibraryToDisk()
    }

    private func loadLibraryFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "audioLibrary"),
           let decoded = try? JSONDecoder().decode([AudioTrack].self, from: data) {
            library = decoded
        }
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlayingFullAdhan = false
            self.flashManager.stop()
        }
    }
}

// MARK: - ============================================================
// MARK: - PRAYER VIEW MODEL
// MARK: - ============================================================

@MainActor
final class PrayerViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    @Published var settings: PrayerSettings {
        didSet {
            persistSettings()
            if !settings.flashEnabled {
                audioManager.flashManager.stop()
            }
        }
    }
    @Published var todayPrayers: [PrayerItem] = []
    @Published var hijriDateString: String = ""
    @Published var gregorianDateString: String = ""
    @Published var fastingToday: FastingCategory = .none
    @Published var nawafilReminders: [NawafilReminder] = []
    @Published var fastingReminders: [FastingReminder] = []
    @Published var memos: [MemoNote] = []
    @Published var personalDuaas: [MemoNote] = []
    @Published var customCities: [CityPreset] = []

    let audioManager = AudioPlayerManager()
    let locationAndCompass = LocationAndCompassManager()
    private let calculator = AstronomicalPrayerCalculator()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        if let data = UserDefaults.standard.data(forKey: "prayerSettings"),
           let decoded = try? JSONDecoder().decode(PrayerSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = PrayerSettings()
        }
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadNawafil()
        loadFastingReminders()
        loadMemos()
        loadPersonalDuaas()
        loadCustomCities()
        requestNotificationAuthorization()
        recomputeToday()

        $settings
            .map(\.selectedCity)
            .removeDuplicates()
            .sink { [weak self] _ in self?.recomputeToday() }
            .store(in: &cancellables)

        $settings
            .map(\.followCurrentLocation)
            .removeDuplicates()
            .sink { [weak self] follow in
                guard let self else { return }
                if follow {
                    self.locationAndCompass.start()
                } else {
                    self.locationAndCompass.stop()
                    self.recomputeToday()
                }
            }
            .store(in: &cancellables)

        locationAndCompass.$currentLocation
            .compactMap { $0 }
            .removeDuplicates { old, new in old.distance(from: new) < 2000 }
            .sink { [weak self] location in
                guard let self, self.settings.followCurrentLocation else { return }
                Task { @MainActor in
                    await self.reverseGeocodeLocation(location)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Géocodage inverse

   
    @MainActor
    func reverseGeocodeLocation(_ location: CLLocation) async {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let tz = TimeZone.current.identifier

        var resolvedCityName = "Ma position"
        var resolvedCountryName = ""

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                resolvedCityName = placemark.locality ?? placemark.name ?? "Ma position"
                resolvedCountryName = placemark.country ?? ""
            }
        } catch {
            print("Erreur géocodage inverse : \(error.localizedDescription)")
        }

        // 🟢 Met à jour les coordonnées dans tous les cas pour recalculer les prières immédiatement
        self.settings.selectedCity = CityPreset(
            name: resolvedCityName,
            country: resolvedCountryName,
            latitude: lat,
            longitude: lon,
            timeZoneIdentifier: tz
        )
        self.recomputeToday()
    }

    // MARK: Calcul quotidien

    func recomputeToday() {
        let city = settings.selectedCity
        guard let tz = TimeZone(identifier: city.timeZoneIdentifier) else { return }

        let fajrAngle = settings.calculationMethod == .custom ? settings.customFajrAngle : settings.calculationMethod.fajrAngle
        let ishaAngle = settings.calculationMethod == .custom ? settings.customIshaAngle : settings.calculationMethod.ishaAngle

        let input = AstronomicalPrayerCalculator.Input(
            date: Date(),
            latitude: city.latitude,
            longitude: city.longitude,
            timeZone: tz,
            fajrAngle: fajrAngle,
            ishaAngle: ishaAngle,
            usesFixedIshaOffset: settings.calculationMethod.usesFixedIshaOffset,
            ishaFixedMinutesAfterMaghrib: settings.calculationMethod.ishaFixedMinutesAfterMaghrib(isRamadan: fastingToday == .ramadan),
            asrShadowFactor: settings.asrMethod.shadowFactor
        )

        guard let output = calculator.calculate(input) else { return }

        let previousModes = Dictionary(uniqueKeysWithValues: todayPrayers.map { ($0.type, $0) })

        todayPrayers = PrayerType.allCases.compactMap { type -> PrayerItem? in
            guard type.isActualPrayer || type == .sunrise else { return nil }
            let time: Date
            switch type {
            case .fajr: time = output.fajr
            case .sunrise: time = output.sunrise
            case .dhuhr: time = output.dhuhr
            case .asr: time = output.asr
            case .maghrib: time = output.maghrib
            case .isha: time = output.isha
            }
            var item = PrayerItem(type: type, time: time)

            if let savedMode = settings.prayerNotificationModes[type.rawValue] {
                item.notificationMode = savedMode
            } else {
                item.notificationMode = settings.defaultNotificationMode
            }

            if let previous = previousModes[type] {
                item.manualOffsetMinutes = previous.manualOffsetMinutes
                item.manualFixedTime = previous.manualFixedTime
                item.assignedAudioTrackID = previous.assignedAudioTrackID
                item.customReminderMinutes = previous.customReminderMinutes
            }
            return item
        }

        updateDateStrings()
        updateFastingStatus()
        scheduleAllNotifications()

        if settings.exportToCalendarEnabled {
            exportPrayerTimesToCalendar { _, _ in }
        }
    }

    private func updateDateStrings() {
        let gregorianFormatter = DateFormatter()
        gregorianFormatter.dateStyle = .full
        gregorianFormatter.locale = Locale(identifier: "fr_FR")
        gregorianDateString = gregorianFormatter.string(from: Date())

        var hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        hijriCalendar.locale = Locale(identifier: "fr_FR")
        let adjustedDate = Calendar.current.date(byAdding: .day, value: settings.hijriDayOffset, to: Date()) ?? Date()
        let hijriFormatter = DateFormatter()
        hijriFormatter.calendar = hijriCalendar
        hijriFormatter.locale = Locale(identifier: "fr_FR")
        hijriFormatter.dateStyle = .long
        hijriDateString = hijriFormatter.string(from: adjustedDate)
    }

    private func updateFastingStatus() {
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 2 || weekday == 5 {
            fastingToday = .mondayThursday
        } else {
            fastingToday = .none
        }
    }

    // MARK: Notifications

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { _, _ in }
        registerNotificationCategories()
    }

    private func registerNotificationCategories() {
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_5MIN", title: "Rappeler dans 5 min", options: [])
        let prayedAction = UNNotificationAction(identifier: "MARK_PRAYED", title: "J'ai prié", options: [])
        let category = UNNotificationCategory(identifier: "PRAYER_CATEGORY", actions: [snoozeAction, prayedAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let originalID = response.notification.request.identifier
        switch response.actionIdentifier {
        case "SNOOZE_5MIN":
            let content = response.notification.request.content.mutableCopy() as? UNMutableNotificationContent ?? UNMutableNotificationContent()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
            let request = UNNotificationRequest(identifier: "\(originalID)_snooze", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        case "MARK_PRAYED":
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
                "\(originalID)_snooze",
                originalID.replacingOccurrences(of: "prayer_", with: "reminder_")
            ])
        default:
            break
        }
        completionHandler()
    }

    func scheduleAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for prayer in todayPrayers where prayer.type.isActualPrayer {
            guard prayer.effectiveTime > Date() else { continue }
            scheduleAdvancedNotification(for: prayer)
            scheduleReminderBefore(prayer: prayer)
        }

        if settings.fajrProgressiveAlarmEnabled, let fajr = todayPrayers.first(where: { $0.type == .fajr }) {
            scheduleFajrProgressiveAlarmNotification(fajr: fajr)
        }
        if settings.fridayKahfReminderEnabled {
            scheduleFridayKahfReminder()
        }
        if settings.fastingEveReminderEnabled {
            scheduleFastingEveReminders()
        }
        scheduleNawafilNotifications()
        scheduleIslamicEventReminders()
    }

    private func scheduleAdvancedNotification(for prayer: PrayerItem) {
        guard prayer.notificationMode != .silent else { return }

        let content = UNMutableNotificationContent()
        content.title = "Heure de \(prayer.type.rawValue)"
        content.body = settings.notificationPreciseTime
            ? "C'est l'heure de la prière de \(prayer.type.rawValue), à \(prayer.effectiveTime.formatted(date: .omitted, time: .shortened))."
            : "C'est l'heure de la prière de \(prayer.type.rawValue)."
        content.categoryIdentifier = "PRAYER_CATEGORY"
        if #available(iOS 15.0, *) {
            content.interruptionLevel = settings.notificationBannerStyle.interruptionLevel
        }

        if settings.notificationSoundEnabled {
            switch prayer.notificationMode {
            case .adhan:
                content.sound = UNNotificationSound(named: UNNotificationSoundName("adhan30.caf"))
            case .beep:
                content.sound = .default
            case .vibrate, .silent:
                content.sound = nil
            }
        } else {
            content.sound = nil
        }

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: prayer.effectiveTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "prayer_\(prayer.type.rawValue)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleReminderBefore(prayer: PrayerItem) {
        let minutes = prayer.customReminderMinutes ?? settings.reminderMinutesBeforePrayer
        guard let reminderDate = Calendar.current.date(byAdding: .minute, value: -minutes, to: prayer.effectiveTime),
              reminderDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Rappel"
        content.body = "\(prayer.type.rawValue) dans \(minutes) minutes."
        content.sound = reminderSound()

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder_\(prayer.type.rawValue)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func reminderSound() -> UNNotificationSound {
        if let trackID = settings.reminderSoundTrackID,
           let track = audioManager.library.first(where: { $0.id == trackID }),
           track.isBuiltIn {
            return UNNotificationSound(named: UNNotificationSoundName(track.fileName))
        }
        return .default
    }

    private func scheduleFajrProgressiveAlarmNotification(fajr: PrayerItem) {
        guard let alarmDate = Calendar.current.date(byAdding: .minute, value: -settings.fajrProgressiveAlarmMinutesBefore, to: fajr.effectiveTime),
              alarmDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Réveil Fajr"
        content.body = "Le réveil progressif pour Fajr commence."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("adhan30.caf"))
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alarmDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "fajr_progressive_alarm", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleFridayKahfReminder() {
        var dateComponents = DateComponents()
        dateComponents.weekday = 6
        dateComponents.hour = 8
        dateComponents.minute = 0
        let content = UNMutableNotificationContent()
        content.title = "Vendredi"
        content.body = "N'oublie pas la lecture de Sourate Al-Kahf aujourd'hui."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "friday_kahf_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleFastingEveReminders() {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

        for reminder in fastingReminders where reminder.isEnabled {
            switch reminder.category {
            case .mondayThursday:
                for eveWeekday in [1, 4] {
                    var components = DateComponents()
                    components.weekday = eveWeekday
                    components.hour = 20
                    components.minute = 0
                    scheduleFastingNotification(
                        identifier: "fasting_\(reminder.id)_\(eveWeekday)",
                        title: reminder.eventTitle.isEmpty ? "Veille de jeûne" : reminder.eventTitle,
                        body: "Demain est un jour de jeûne recommandé (lundi/jeudi).",
                        soundType: reminder.soundType,
                        customSoundTrackID: reminder.customSoundTrackID,
                        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    )
                }

            case .whiteDays, .ramadan:
                for dayOffset in 0..<45 {
                    guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
                    let hijriDay = hijriCalendar.component(.day, from: date)
                    let hijriMonth = hijriCalendar.component(.month, from: date)
                    let matches = reminder.category == .whiteDays
                        ? [13, 14, 15].contains(hijriDay)
                        : hijriMonth == 9

                    guard matches else { continue }
                    let minutesBefore = reminder.reminderMinutesBeforeImsak
                    guard let eveDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: Calendar.current.startOfDay(for: date)),
                          eveDate > Date() else { continue }

                    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: eveDate)
                    scheduleFastingNotification(
                        identifier: "fasting_\(reminder.id)_\(dayOffset)",
                        title: reminder.eventTitle.isEmpty ? reminder.category.rawValue : reminder.eventTitle,
                        body: reminder.category == .ramadan ? "Nuit de Ramadan : pense au Suhoor." : "Jour blanc à venir.",
                        soundType: reminder.soundType,
                        customSoundTrackID: reminder.customSoundTrackID,
                        trigger: UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                    )
                }

            case .none:
                break
            }
        }
    }

    private func scheduleFastingNotification(identifier: String, title: String, body: String, soundType: ReminderSoundType, customSoundTrackID: UUID? = nil, trigger: UNCalendarNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let trackID = customSoundTrackID,
           let track = audioManager.library.first(where: { $0.id == trackID }),
           track.isBuiltIn {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(track.fileName))
        } else {
            switch soundType {
            case .defaultSound: content.sound = .default
            case .chime: content.sound = UNNotificationSound(named: UNNotificationSoundName("chime.caf"))
            case .none: content.sound = nil
            }
        }
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleNawafilNotifications() {
        for reminder in nawafilReminders where reminder.isEnabled {
            for weekday in reminder.repeatingWeekdays {
                var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
                dateComponents.weekday = weekday
                let content = UNMutableNotificationContent()
                content.title = "Nawafil : \(reminder.title)"
                content.body = reminder.note.isEmpty ? "C'est l'heure de ta prière surérogatoire." : reminder.note
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "nawafil_\(reminder.id)_\(weekday)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func scheduleIslamicEventReminders() {
        for event in IslamicEvent.all where settings.enabledIslamicEventReminders[event.name] == true {
            scheduleIslamicEventReminder(for: event)
        }
    }

    func scheduleIslamicEventReminder(for event: IslamicEvent) {
        guard let date = event.nextOccurrence() else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        guard let triggerDate = Calendar.current.date(from: components), triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = event.name
        content.body = "Aujourd'hui : \(event.name)."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "islamic_event_\(event.name)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelIslamicEventReminder(for event: IslamicEvent) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["islamic_event_\(event.name)"])
    }

    // MARK: Flash

    func triggerFlashTest() {
        if audioManager.isFlashCurrentlyActive {
            audioManager.flashManager.stop()
        } else {
            audioManager.flashManager.flash(duration: settings.flashDuration, pattern: settings.flashPattern)
        }
    }

    // MARK: Actions par prière

    func updateNotificationMode(for prayerType: PrayerType, mode: NotificationMode) {
        guard let index = todayPrayers.firstIndex(where: { $0.type == prayerType }) else { return }
        todayPrayers[index].notificationMode = mode
        settings.prayerNotificationModes[prayerType.rawValue] = mode
        scheduleAllNotifications()
    }

    func setPrayerOffset(for type: PrayerType, offset: Int) {
        guard let index = todayPrayers.firstIndex(where: { $0.type == type }) else { return }
        todayPrayers[index].manualOffsetMinutes = offset
        scheduleAllNotifications()
    }

    func setCustomReminder(for type: PrayerType, minutes: Int?) {
        guard let index = todayPrayers.firstIndex(where: { $0.type == type }) else { return }
        todayPrayers[index].customReminderMinutes = minutes
        scheduleAllNotifications()
    }

    func nextPrayer() -> PrayerItem? {
        let now = Date()
        return todayPrayers
            .filter { $0.type.isActualPrayer && $0.effectiveTime > now }
            .sorted { $0.effectiveTime < $1.effectiveTime }
            .first
    }

    func progressToNextPrayer() -> Double {
        guard let next = nextPrayer() else { return 0 }
        let actualPrayers = todayPrayers.filter { $0.type.isActualPrayer }.sorted { $0.effectiveTime < $1.effectiveTime }
        guard let nextIndex = actualPrayers.firstIndex(where: { $0.id == next.id }) else { return 0 }
        let previousTime = nextIndex > 0 ? actualPrayers[nextIndex - 1].effectiveTime : Calendar.current.startOfDay(for: Date())
        let total = next.effectiveTime.timeIntervalSince(previousTime)
        let elapsed = Date().timeIntervalSince(previousTime)
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }

    // MARK: Export vers le Calendrier

    func exportPrayerTimesToCalendar(completion: @escaping (Bool, String?) -> Void) {
        let eventStore = EKEventStore()
        Task { @MainActor in
            do {
                let granted: Bool
                if #available(iOS 17.0, *) {
                    granted = try await eventStore.requestFullAccessToEvents()
                } else {
                    granted = try await withCheckedThrowingContinuation { continuation in
                        eventStore.requestAccess(to: .event) { success, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(returning: success)
                            }
                        }
                    }
                }
                guard granted else {
                    completion(false, "Accès au calendrier refusé. Vérifie Réglages > Confidentialité > Calendriers.")
                    return
                }
                var successCount = 0
                for prayer in self.todayPrayers where prayer.type.isActualPrayer {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = "🕌 \(prayer.type.rawValue)"
                    event.startDate = prayer.effectiveTime
                    event.endDate = prayer.effectiveTime.addingTimeInterval(15 * 60)
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    do {
                        try eventStore.save(event, span: .thisEvent)
                        successCount += 1
                    } catch {
                        continue
                    }
                }
                completion(successCount > 0, successCount == 0 ? "Aucun horaire n'a pu être exporté." : nil)
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }

    // MARK: Persistance

    private func persistSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "prayerSettings")
        }
    }

    private func loadNawafil() {
        if let data = UserDefaults.standard.data(forKey: "nawafilReminders"),
           let decoded = try? JSONDecoder().decode([NawafilReminder].self, from: data) {
            nawafilReminders = decoded
        }
    }

    func saveNawafil() {
        if let data = try? JSONEncoder().encode(nawafilReminders) {
            UserDefaults.standard.set(data, forKey: "nawafilReminders")
        }
        scheduleAllNotifications()
    }

    private func loadFastingReminders() {
        if let data = UserDefaults.standard.data(forKey: "fastingReminders"),
           let decoded = try? JSONDecoder().decode([FastingReminder].self, from: data) {
            fastingReminders = decoded
        }
    }

    func saveFastingReminders() {
        if let data = try? JSONEncoder().encode(fastingReminders) {
            UserDefaults.standard.set(data, forKey: "fastingReminders")
        }
        scheduleAllNotifications()
    }

    private func loadMemos() {
        if let data = UserDefaults.standard.data(forKey: "memoNotes"),
           let decoded = try? JSONDecoder().decode([MemoNote].self, from: data) {
            memos = decoded
        }
    }

    func saveMemos() {
        if let data = try? JSONEncoder().encode(memos) {
            UserDefaults.standard.set(data, forKey: "memoNotes")
        }
    }

    private func loadPersonalDuaas() {
        if let data = UserDefaults.standard.data(forKey: "personalDuaas"),
           let decoded = try? JSONDecoder().decode([MemoNote].self, from: data) {
            personalDuaas = decoded
        }
    }

    func savePersonalDuaas() {
        if let data = try? JSONEncoder().encode(personalDuaas) {
            UserDefaults.standard.set(data, forKey: "personalDuaas")
        }
    }

    private func loadCustomCities() {
        if let data = UserDefaults.standard.data(forKey: "customCities"),
           let decoded = try? JSONDecoder().decode([CityPreset].self, from: data) {
            customCities = decoded
        }
    }

    func saveCustomCities() {
        if let data = try? JSONEncoder().encode(customCities) {
            UserDefaults.standard.set(data, forKey: "customCities")
        }
    }

    // MARK: Sauvegarde / restauration

    struct BackupData: Codable {
        var settings: PrayerSettings
        var nawafilReminders: [NawafilReminder]
        var fastingReminders: [FastingReminder]
        var memos: [MemoNote]
        var personalDuaas: [MemoNote]
        var customCities: [CityPreset]
    }

    func exportBackupFile() -> URL? {
        let backup = BackupData(
            settings: settings,
            nawafilReminders: nawafilReminders,
            fastingReminders: fastingReminders,
            memos: memos,
            personalDuaas: personalDuaas,
            customCities: customCities
        )
        guard let data = try? JSONEncoder().encode(backup) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("adhanapp_backup.json")
        do {
            try data.write(to: url, options: Data.WritingOptions.atomic)
            return url
        } catch {
            return nil
        }
    }

    @discardableResult
    func importBackupFile(from url: URL) -> Bool {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let backup = try? JSONDecoder().decode(BackupData.self, from: data) else { return false }

        settings = backup.settings
        nawafilReminders = backup.nawafilReminders
        fastingReminders = backup.fastingReminders
        memos = backup.memos
        personalDuaas = backup.personalDuaas
        customCities = backup.customCities

        saveNawafil()
        saveFastingReminders()
        saveMemos()
        savePersonalDuaas()
        saveCustomCities()
        recomputeToday()
        return true
    }
}

// MARK: - ============================================================
// MARK: - VUES SWIFTUI
// MARK: - ============================================================

struct ContentView: View {
    @StateObject private var viewModel = PrayerViewModel()
    @State private var now = Date()
    @State private var showSettings = false
    @State private var showAudioLibrary = false
    @State private var showCityPicker = false
    @State private var showQibla = false
    @State private var showFasting = false
    @State private var showNawafil = false
    @State private var showMemos = false
    @State private var showDuaa = false
    @State private var showSunna = false
    @State private var showImportantDates = false
    @State private var showSupport = false

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    clockSection
                    nextPrayerCard
                    imsakIftarBanner
                    prayerListCard
                    quickAccessGrid
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .onReceive(clockTimer) { date in now = date }
            .onAppear {
                viewModel.locationAndCompass.requestAuthorization()
                if viewModel.settings.followCurrentLocation {
                    viewModel.locationAndCompass.start()
                }
                viewModel.recomputeToday()
            }
            .preferredColorScheme(viewModel.settings.preferredColorScheme.colorScheme)
            .sheet(isPresented: $showSettings) { SettingsSheet(viewModel: viewModel) }
            .sheet(isPresented: $showAudioLibrary) { AudioSheet(viewModel: viewModel) }
            .sheet(isPresented: $showCityPicker) { CitySheet(viewModel: viewModel) }
            .sheet(isPresented: $showQibla) { QiblaSheet(viewModel: viewModel) }
            .sheet(isPresented: $showFasting) { FastingSheet(viewModel: viewModel) }
            .sheet(isPresented: $showNawafil) { NawafilSheet(viewModel: viewModel) }
            .sheet(isPresented: $showMemos) { MemoSheet(viewModel: viewModel) }
            .sheet(isPresented: $showDuaa) { DuaaSheet(viewModel: viewModel) }
            .sheet(isPresented: $showSunna) { SunnaSheet(viewModel: viewModel) }
            .sheet(isPresented: $showImportantDates) { ImportantDatesSheet(viewModel: viewModel) }
            .sheet(isPresented: $showSupport) { SupportSheet() }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ADHAN")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Color.adhanPrimary)

            Button { showCityPicker = true } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.settings.selectedCity.name)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        Text(viewModel.gregorianDateString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.hijriDateString)
                            .font(.caption)
                            .foregroundStyle(Color.adhanGold)
                    }
                    Spacer()
                    Image(systemName: "location.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.adhanPrimary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary, lineWidth: 1))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    private var clockSection: some View {
        Text(now.formatted(date: .omitted, time: .standard))
            .font(.system(.title, design: .monospaced).weight(.semibold))
            .foregroundStyle(Color.adhanPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    private var nextPrayerCard: some View {
        let next = viewModel.nextPrayer()
        return VStack(spacing: 12) {
            HStack {
                Image(systemName: next?.type.systemImage ?? "moon.stars.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.adhanPrimary)
                VStack(alignment: .leading) {
                    Text("Prochaine prière")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(next?.type.rawValue ?? "—")
                        .font(.title.bold())
                }
                Spacer()
                if let next {
                    Text(next.effectiveTime, style: .time)
                        .font(.title2.monospacedDigit())
                }
            }
            if let next {
                ProgressView(value: viewModel.progressToNextPrayer())
                    .tint(Color.progressTint)

                HStack {
                    Text(next.effectiveTime, style: .relative)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: next.notificationMode.systemImage)
                        Text(next.notificationMode.rawValue)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.adhanPrimary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var imsakIftarBanner: some View {
        HStack(spacing: 12) {
            if let fajr = viewModel.todayPrayers.first(where: { $0.type == .fajr }) {
                bannerItem(title: "Imsak", time: Calendar.current.date(byAdding: .minute, value: -10, to: fajr.effectiveTime) ?? fajr.effectiveTime, icon: "moon.fill")
            }
            if let maghrib = viewModel.todayPrayers.first(where: { $0.type == .maghrib }) {
                bannerItem(title: "Iftar", time: maghrib.effectiveTime, icon: "fork.knife")
            }
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.softAlert)
                Text(viewModel.fastingToday.rawValue)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.adhanGold.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.adhanGold.opacity(0.3), lineWidth: 1))
    }

    private func bannerItem(title: String, time: Date, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(Color.adhanPrimary)
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(time, style: .time).font(.footnote.bold())
        }
        .frame(maxWidth: .infinity)
    }

    private var prayerListCard: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.todayPrayers) { prayer in
                PrayerRow(prayer: prayer, viewModel: viewModel)
                if prayer.id != viewModel.todayPrayers.last?.id {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var quickAccessGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickAccessButton(title: "Adhans", icon: "waveform") { showAudioLibrary = true }
            quickAccessButton(title: "Qibla", icon: "location.north.line.fill") { showQibla = true }
            quickAccessButton(title: "Jeûne", icon: "moon.dust.fill") { showFasting = true }
            quickAccessButton(title: "Nawafil", icon: "sparkles") { showNawafil = true }
            quickAccessButton(title: "Mémos", icon: "note.text") { showMemos = true }
            quickAccessButton(title: "Douaas", icon: "hands.sparkles.fill") { showDuaa = true }
            quickAccessButton(title: "Sunnan", icon: "book.fill") { showSunna = true }
            quickAccessButton(title: "Dates clés", icon: "calendar.badge.clock") { showImportantDates = true }
            quickAccessButton(title: "Soutenir", icon: "heart.fill") { showSupport = true }

            ShareLink(item: shareText) {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up").font(.title2)
                    Text("Partager").font(.caption)
                }
                .frame(maxWidth: .infinity, minHeight: 70)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.quaternary, lineWidth: 1))
                .foregroundStyle(Color.adhanPrimary)
            }
        }
    }

    private var shareText: String {
        var lines = ["🕌 Horaires de prière — \(viewModel.settings.selectedCity.name)", viewModel.gregorianDateString, ""]
        for prayer in viewModel.todayPrayers {
            lines.append("\(prayer.type.rawValue) : \(prayer.effectiveTime.formatted(date: .omitted, time: .shortened))")
        }
        lines.append("")
        lines.append("Envoyé depuis Adhan")
        return lines.joined(separator: "\n")
    }

    private func quickAccessButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.quaternary, lineWidth: 1))
            .foregroundStyle(Color.adhanPrimary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: PrayerRow

struct PrayerRow: View {
    let prayer: PrayerItem
    @ObservedObject var viewModel: PrayerViewModel

    var body: some View {
        HStack {
            Image(systemName: prayer.type.systemImage)
                .foregroundStyle(Color.adhanPrimary)
                .frame(width: 28)

            Text(prayer.type.rawValue)
                .font(.body.weight(.medium))

            Spacer()

            Text(prayer.effectiveTime, style: .time)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)

            if prayer.type.isActualPrayer {
                Menu {
                    ForEach(NotificationMode.allCases) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.updateNotificationMode(for: prayer.type, mode: mode)
                            }
                        } label: {
                            Label(mode.rawValue, systemImage: mode.systemImage)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: prayer.notificationMode.systemImage)
                            .foregroundStyle(Color.adhanGold)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.adhanGold.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .contextMenu {
            if prayer.type.isActualPrayer {
                Menu("Mode de sonnerie") {
                    ForEach(NotificationMode.allCases) { mode in
                        Button {
                            viewModel.updateNotificationMode(for: prayer.type, mode: mode)
                        } label: {
                            Label(mode.rawValue, systemImage: mode.systemImage)
                        }
                    }
                }
                Menu("Décalage manuel") {
                    ForEach([-10, -5, 0, 5, 10], id: \.self) { minutes in
                        Button(minutes == 0 ? "Aucun décalage" : (minutes > 0 ? "+\(minutes) min" : "\(minutes) min")) {
                            viewModel.setPrayerOffset(for: prayer.type, offset: minutes)
                        }
                    }
                }
                Menu("Rappel avant") {
                    Button("Défaut (global)") { viewModel.setCustomReminder(for: prayer.type, minutes: nil) }
                    ForEach([5, 10, 15, 20], id: \.self) { minutes in
                        Button("\(minutes) min") { viewModel.setCustomReminder(for: prayer.type, minutes: minutes) }
                    }
                }
            }
        }
    }
}

// MARK: SupportSheet

struct SupportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitManager()
    @State private var showPrivacyPolicy = false
    @State private var showSupportPage = false
    @State private var showTermsPage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 58))
                            .foregroundStyle(Color.adhanGold)

                        Text("Soutenir Adhan")
                            .font(.title2.bold())

                        Text("L'application est et restera 100% gratuite, sans publicité et sans revente de données.\n\nCet achat est totalement facultatif. Votre contribution aide à couvrir les frais annuels du compte développeur Apple et à maintenir les futures mises à jour.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary, lineWidth: 1))

                    if store.isLoadingProducts {
                        ProgressView("Chargement…")
                            .padding()
                    } else if let error = store.loadError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.availableProducts) { product in
                                supportOptionCard(product: product)
                            }
                        }
                    }

                    if store.isPurchasing {
                        ProgressView()
                    }

                    if !store.purchaseStateMessage.isEmpty {
                        Text(store.purchaseStateMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.adhanPrimary)
                            .padding()
                    }

                    VStack(spacing: 16) {
                        Text("Besoin d'aide ?")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Button {
                            showSupportPage = true
                        } label: {
                            Label("Visiter la page Support", systemImage: "questionmark.circle.fill")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.adhanPrimary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        Button {
                            if let url = URL(string: "mailto:contact.abdessemed@gmail.com") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Contacter le support", systemImage: "envelope.fill")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cardBackground)
                                .foregroundStyle(Color.adhanPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adhanPrimary, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary, lineWidth: 1))

                    VStack(spacing: 12) {
                        Text("Informations légales")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Button {
                            showPrivacyPolicy = true
                        } label: {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundStyle(Color.adhanPrimary)
                                    .frame(width: 28)
                                Text("Politique de confidentialité")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        Divider()

                        Button {
                            showTermsPage = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(Color.adhanPrimary)
                                    .frame(width: 28)
                                Text("Conditions d'utilisation")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary, lineWidth: 1))
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Soutenir le projet")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                LegalWebView(urlString: "https://nebios7.github.io/adhan-support/adhan-privacy.html", title: "Confidentialité")
            }
            .sheet(isPresented: $showSupportPage) {
                LegalWebView(urlString: "https://nebios7.github.io/adhan-support/", title: "Support")
            }
            .sheet(isPresented: $showTermsPage) {
                LegalWebView(urlString: "https://nebios7.github.io/adhan-support/adhan-terms.html", title: "Conditions")
            }
        }
    }

    private func supportOptionCard(product: Product) -> some View {
        Button {
            Task { await store.buy(product) }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(Color.adhanPrimary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.body.bold())
                        .foregroundStyle(.primary)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.callout.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.adhanPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.quaternary, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(store.isPurchasing)
    }
}

// MARK: LegalWebView

struct LegalWebView: View {
    let urlString: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let url = URL(string: urlString) {
                    WebView(url: url, isLoading: $isLoading, loadError: $loadError)
                        .overlay {
                            if isLoading {
                                ProgressView("Chargement…")
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
                            }
                        }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.softAlert)
                        Text("URL invalide")
                            .font(.headline)
                        Text("Impossible de charger la page demandée.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                if let loadError {
                    Text(loadError)
                        .font(.caption)
                        .foregroundStyle(Color.softAlert)
                        .padding()
                        .background(Color.softAlert.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
        }
    }
}

// MARK: SettingsSheet

struct SettingsSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var backupURL: URL?
    @State private var showImportPicker = false
    @State private var importSucceeded = false
    @State private var showImportResultAlert = false
    @State private var calendarExportMessage = ""
    @State private var showCalendarExportAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Méthode de calcul") {
                    Picker("Méthode", selection: $viewModel.settings.calculationMethod) {
                        ForEach(CalculationMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    if viewModel.settings.calculationMethod == .custom {
                        Stepper("Angle Fajr : \(Int(viewModel.settings.customFajrAngle))°",
                                value: $viewModel.settings.customFajrAngle, in: 10...20)
                        Stepper("Angle Isha : \(Int(viewModel.settings.customIshaAngle))°",
                                value: $viewModel.settings.customIshaAngle, in: 10...20)
                    }
                    LabeledContent("École Asr", value: viewModel.settings.asrMethod.rawValue)
                }

                Section("Calendrier hégirien") {
                    Stepper("Décalage : \(viewModel.settings.hijriDayOffset) j",
                            value: $viewModel.settings.hijriDayOffset, in: -3...3)
                }

                Section("Rappels") {
                    Picker("Sonnerie par défaut", selection: $viewModel.settings.defaultNotificationMode) {
                        ForEach(NotificationMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.systemImage).tag(mode)
                        }
                    }
                    Stepper("Rappel avant prière : \(viewModel.settings.reminderMinutesBeforePrayer) min",
                            value: $viewModel.settings.reminderMinutesBeforePrayer, in: 5...30, step: 5)
                    Toggle("Réveil Fajr progressif", isOn: $viewModel.settings.fajrProgressiveAlarmEnabled)
                    if viewModel.settings.fajrProgressiveAlarmEnabled {
                        Stepper("Début : \(viewModel.settings.fajrProgressiveAlarmMinutesBefore) min avant",
                                value: $viewModel.settings.fajrProgressiveAlarmMinutesBefore, in: 5...30, step: 5)
                    }
                    Toggle("Rappel Vendredi (Al-Kahf)", isOn: $viewModel.settings.fridayKahfReminderEnabled)
                    Toggle("Alerte veille de jeûne", isOn: $viewModel.settings.fastingEveReminderEnabled)
                }

                Section {
                    Toggle("Son des notifications", isOn: $viewModel.settings.notificationSoundEnabled)
                    Picker("Style de bannière", selection: $viewModel.settings.notificationBannerStyle) {
                        ForEach(NotificationBannerStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    Toggle("Afficher l'heure précise", isOn: $viewModel.settings.notificationPreciseTime)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Le type d'alerte (Adhan/Bip/Vibreur/Silencieux) se règle directement sur chaque prière dans la liste principale.")
                }

                Section {
                    Toggle("Suivre ma position en temps réel", isOn: $viewModel.settings.followCurrentLocation)
                    Picker("Thème", selection: $viewModel.settings.preferredColorScheme) {
                        ForEach(AppColorScheme.allCases) { scheme in
                            Text(scheme.rawValue).tag(scheme)
                        }
                    }
                } header: {
                    Text("Apparence et localisation")
                }

                Section {
                    Toggle("Export automatique quotidien", isOn: $viewModel.settings.exportToCalendarEnabled)
                    Button {
                        viewModel.exportPrayerTimesToCalendar { success, error in
                            calendarExportMessage = success ? "Horaires exportés avec succès." : (error ?? "Échec de l'export.")
                            showCalendarExportAlert = true
                        }
                    } label: {
                        Label("Exporter maintenant", systemImage: "calendar.badge.plus")
                    }
                    ForEach(IslamicEvent.all) { event in
                        Toggle(event.name, isOn: Binding(
                            get: { viewModel.settings.enabledIslamicEventReminders[event.name, default: false] },
                            set: { newValue in
                                viewModel.settings.enabledIslamicEventReminders[event.name] = newValue
                                if newValue {
                                    viewModel.scheduleIslamicEventReminder(for: event)
                                } else {
                                    viewModel.cancelIslamicEventReminder(for: event)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Calendrier et dates clés")
                }

                Section {
                    Picker("Son des rappels", selection: $viewModel.settings.reminderSoundTrackID) {
                        Text("Son par défaut").tag(UUID?.none)
                        ForEach(viewModel.audioManager.library.filter { $0.isBuiltIn }) { track in
                            Text(track.displayName).tag(Optional(track.id))
                        }
                    }
                } header: {
                    Text("Son personnalisé pour les rappels")
                }

                Section {
                    Toggle("Activer le flash visuel", isOn: $viewModel.settings.flashEnabled)
                    if viewModel.settings.flashEnabled {
                        Stepper("Durée : \(Int(viewModel.settings.flashDuration))s",
                                value: $viewModel.settings.flashDuration, in: 2...15, step: 1)
                        Picker("Rythme", selection: $viewModel.settings.flashPattern) {
                            ForEach(FlashPattern.allCases) { pattern in
                                Text(pattern.rawValue).tag(pattern)
                            }
                        }
                        .pickerStyle(.segmented)
                        Button("Tester le flash") {
                            viewModel.triggerFlashTest()
                        }
                    }
                } header: {
                    Text("Rappel visuel (flash)")
                }

                Section {
                    Picker("Durée de lecture", selection: $viewModel.settings.globalPlaybackDuration) {
                        ForEach(AdhanPlaybackDuration.allCases) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(value: $viewModel.settings.adhanVolume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                    }
                } header: {
                    Text("Réglages Audio")
                }

                Section("Sauvegarde et restauration") {
                    if let url = backupURL {
                        ShareLink(item: url) {
                            Label("Partager la sauvegarde JSON", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button("Générer un fichier de sauvegarde") {
                            backupURL = viewModel.exportBackupFile()
                        }
                    }

                    Button("Importer une sauvegarde") {
                        showImportPicker = true
                    }
                }
            }
            .navigationTitle("Réglages")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .alert("Export Calendrier", isPresented: $showCalendarExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(calendarExportMessage)
            }
            .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    importSucceeded = viewModel.importBackupFile(from: url)
                    showImportResultAlert = true
                case .failure:
                    importSucceeded = false
                    showImportResultAlert = true
                }
            }
            .alert("Restauration", isPresented: $showImportResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importSucceeded ? "Les données ont été restaurées avec succès." : "Échec de la restauration du fichier.")
            }
        }
    }
}

// MARK: AudioSheet

struct AudioSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDocumentPicker = false
    @State private var newTrackName = ""
    @State private var trackToRename: AudioTrack? = nil
    @State private var showRenameAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("Adhan principal") {
                    Picker("Récitateur par défaut", selection: $viewModel.settings.defaultAudioTrackID) {
                        Text("Premier de la liste").tag(UUID?.none)
                        ForEach(viewModel.audioManager.library) { track in
                            Text(track.displayName).tag(Optional(track.id))
                        }
                    }
                }

                Section("Bibliothèque locale") {
                    ForEach(viewModel.audioManager.library) { track in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(track.displayName).font(.body.weight(.medium))
                                Text(track.isBuiltIn ? "Intégré" : "Importé").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                viewModel.audioManager.testPlay(track: track, volume: viewModel.settings.adhanVolume)
                            } label: {
                                Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(Color.adhanPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !track.isBuiltIn {
                                Button(role: .destructive) {
                                    viewModel.audioManager.deleteTrack(track)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                                Button {
                                    trackToRename = track
                                    newTrackName = track.displayName
                                    showRenameAlert = true
                                } label: {
                                    Label("Renommer", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showDocumentPicker = true
                    } label: {
                        Label("Importer un fichier audio (MP3/M4A)", systemImage: "doc.badge.plus")
                    }
                }
            }
            .navigationTitle("Bibliothèque Adhans")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        viewModel.audioManager.stopPlayback()
                        dismiss()
                    }
                }
            }
            .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.audio]) { result in
                if case .success(let url) = result {
                    viewModel.audioManager.importAudioFile(from: url, displayName: url.deletingPathExtension().lastPathComponent)
                }
            }
            .alert("Renommer la piste", isPresented: $showRenameAlert) {
                TextField("Nouveau nom", text: $newTrackName)
                Button("Annuler", role: .cancel) {}
                Button("Enregistrer") {
                    if let track = trackToRename {
                        viewModel.audioManager.renameTrack(track, to: newTrackName)
                    }
                }
            }
        }
    }
}

// MARK: CitySheet

struct CitySheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showAddCityAlert = false
    @State private var newCityName = ""
    @State private var newCityCountry = ""
    @State private var newCityLat = ""
    @State private var newCityLon = ""

    var allCities: [CityPreset] {
        CityPreset.defaults + viewModel.customCities
    }

    var filteredCities: [CityPreset] {
        if searchText.isEmpty { return allCities }
        return allCities.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.country.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Suivre ma position GPS", isOn: $viewModel.settings.followCurrentLocation)
                }

                Section("Villes") {
                    ForEach(filteredCities) { city in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(city.name).font(.body.weight(.medium))
                                Text(city.country).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.settings.selectedCity == city && !viewModel.settings.followCurrentLocation {
                                Image(systemName: "checkmark").foregroundStyle(Color.adhanPrimary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.settings.followCurrentLocation = false
                            viewModel.settings.selectedCity = city
                            dismiss()
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Chercher une ville...")
            .navigationTitle("Sélection de la ville")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAddCityAlert = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .alert("Ajouter une ville", isPresented: $showAddCityAlert) {
                TextField("Nom (ex: Lille)", text: $newCityName)
                TextField("Pays (ex: France)", text: $newCityCountry)
                TextField("Latitude (ex: 50.6292)", text: $newCityLat)
                TextField("Longitude (ex: 3.0573)", text: $newCityLon)
                Button("Annuler", role: .cancel) {}
                Button("Ajouter") {
                    if let lat = Double(newCityLat), let lon = Double(newCityLon), !newCityName.isEmpty {
                        let city = CityPreset(name: newCityName, country: newCityCountry, latitude: lat, longitude: lon, timeZoneIdentifier: TimeZone.current.identifier)
                        viewModel.customCities.append(city)
                        viewModel.saveCustomCities()
                    }
                }
            }
        }
    }
}

// MARK: QiblaSheet

struct QiblaSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                let lat = viewModel.locationAndCompass.currentLocation?.coordinate.latitude ?? viewModel.settings.selectedCity.latitude
                let lon = viewModel.locationAndCompass.currentLocation?.coordinate.longitude ?? viewModel.settings.selectedCity.longitude
                let qiblaBearing = AstronomicalPrayerCalculator.qiblaBearing(fromLat: lat, lon: lon)
                let distance = AstronomicalPrayerCalculator.distanceToMecca(fromLat: lat, lon: lon)
                let currentHeading = viewModel.locationAndCompass.smoothedHeadingDegrees
                let needleAngle = qiblaBearing - currentHeading

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.adhanPrimary.opacity(0.2), lineWidth: 12)
                        .frame(width: 260, height: 260)

                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 240, height: 240)
                        .shadow(radius: 4)

                    VStack {
                        Text("N")
                            .font(.headline.bold())
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .frame(height: 220)
                    .rotationEffect(.degrees(-currentHeading))

                    Image(systemName: "location.north.line.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(Color.adhanGold)
                        .rotationEffect(.degrees(needleAngle))
                }

                VStack(spacing: 8) {
                    Text("Cap Qibla : \(Int(qiblaBearing))°")
                        .font(.title2.bold())
                    Text("Distance de La Mecque : \(Int(distance)) km")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.appBackground)
            .navigationTitle("Direction de la Qibla")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear { viewModel.locationAndCompass.start() }
            .onDisappear {
                if !viewModel.settings.followCurrentLocation {
                    viewModel.locationAndCompass.stop()
                }
            }
        }
    }
}

// MARK: FastingSheet

struct FastingSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddAlert = false
    @State private var selectedCategory: FastingCategory = .mondayThursday
    @State private var minutesBefore: Int = 60
    @State private var title: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Aujourd'hui") {
                    LabeledContent("Statut", value: viewModel.fastingToday.rawValue)
                }

                Section("Rappels programmés") {
                    ForEach($viewModel.fastingReminders) { $reminder in
                        Toggle(reminder.eventTitle.isEmpty ? reminder.category.rawValue : reminder.eventTitle, isOn: $reminder.isEnabled)
                            .onChange(of: reminder.isEnabled) { _ in viewModel.saveFastingReminders() }
                    }
                    .onDelete { indexSet in
                        viewModel.fastingReminders.remove(atOffsets: indexSet)
                        viewModel.saveFastingReminders()
                    }
                }
            }
            .navigationTitle("Suivi du Jeûne")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAddAlert = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddAlert) {
                NavigationStack {
                    Form {
                        Picker("Type de jeûne", selection: $selectedCategory) {
                            ForEach(FastingCategory.allCases.filter { $0 != .none }) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        TextField("Titre du rappel (optionnel)", text: $title)
                        Stepper("Rappel avant Imsak : \(minutesBefore) min", value: $minutesBefore, in: 15...120, step: 15)
                    }
                    .navigationTitle("Nouveau rappel")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { showAddAlert = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Ajouter") {
                                let reminder = FastingReminder(category: selectedCategory, isEnabled: true, reminderMinutesBeforeImsak: minutesBefore, eventTitle: title)
                                viewModel.fastingReminders.append(reminder)
                                viewModel.saveFastingReminders()
                                showAddAlert = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: NawafilSheet

struct NawafilSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false
    @State private var title = ""
    @State private var time = Date()
    @State private var note = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach($viewModel.nawafilReminders) { $item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.title).font(.headline)
                            Text(item.time, style: .time).font(.subheadline).foregroundStyle(.secondary)
                            if !item.note.isEmpty { Text(item.note).font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Toggle("", isOn: $item.isEnabled)
                            .onChange(of: item.isEnabled) { _ in viewModel.saveNawafil() }
                    }
                }
                .onDelete { indexSet in
                    viewModel.nawafilReminders.remove(atOffsets: indexSet)
                    viewModel.saveNawafil()
                }
            }
            .navigationTitle("Prières Nawafil")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    Form {
                        TextField("Nom (ex: Duha, Tahajjud)", text: $title)
                        DatePicker("Heure", selection: $time, displayedComponents: .hourAndMinute)
                        TextField("Note / Invocation (optionnel)", text: $note)
                    }
                    .navigationTitle("Ajouter Nafla")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { showAdd = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Ajouter") {
                                if !title.isEmpty {
                                    let item = NawafilReminder(title: title, time: time, isEnabled: true, note: note)
                                    viewModel.nawafilReminders.append(item)
                                    viewModel.saveNawafil()
                                    showAdd = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: MemoSheet

struct MemoSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false
    @State private var title = ""
    @State private var content = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.memos) { memo in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memo.title).font(.headline)
                        Text(memo.content).font(.body)
                        Text(memo.createdAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    viewModel.memos.remove(atOffsets: indexSet)
                    viewModel.saveMemos()
                }
            }
            .navigationTitle("Mémos Spirituels")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    Form {
                        TextField("Titre", text: $title)
                        TextEditor(text: $content).frame(height: 120)
                    }
                    .navigationTitle("Nouveau mémo")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { showAdd = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Enregistrer") {
                                if !title.isEmpty {
                                    let memo = MemoNote(title: title, content: content)
                                    viewModel.memos.append(memo)
                                    viewModel.saveMemos()
                                    showAdd = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: DuaaSheet

struct DuaaSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false
    @State private var title = ""
    @State private var content = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.personalDuaas) { duaa in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(duaa.title).font(.headline).foregroundStyle(Color.adhanPrimary)
                        Text(duaa.content).font(.body)
                    }
                }
                .onDelete { indexSet in
                    viewModel.personalDuaas.remove(atOffsets: indexSet)
                    viewModel.savePersonalDuaas()
                }
            }
            .navigationTitle("Mes Douaas")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    Form {
                        TextField("Sujet / Occasion", text: $title)
                        TextEditor(text: $content).frame(height: 120)
                    }
                    .navigationTitle("Nouvelle Douaa")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { showAdd = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Enregistrer") {
                                if !title.isEmpty {
                                    let item = MemoNote(title: title, content: content)
                                    viewModel.personalDuaas.append(item)
                                    viewModel.savePersonalDuaas()
                                    showAdd = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: SunnaSheet

struct SunnaSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss

    let sunnanList = [
        ("Siwak", "Utiliser le Siwak avant chaque prière et après le réveil."),
        ("Prières Rawatib", "12 rak'ats surérogatoires quotidiennes liées aux prières obligatoires."),
        ("Lecture de Sourate Al-Kahf", "Le vendredi, illumination entre les deux vendredis."),
        ("Invocations du matin et du soir", "Protection et rappel quotidien (Adhkar)."),
        ("Prière du Duha", "2 à 8 rak'ats au cours de la matinée.")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sunnanList, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.0).font(.headline).foregroundStyle(Color.adhanPrimary)
                        Text(item.1).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Sunnan Récompensées")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}

// MARK: ImportantDatesSheet

struct ImportantDatesSheet: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(IslamicEvent.all) { event in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(event.name).font(.headline)
                            if let date = event.nextOccurrence() {
                                Text("Prochaine date : \(date.formatted(date: .long, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { viewModel.settings.enabledIslamicEventReminders[event.name, default: false] },
                            set: { newValue in
                                viewModel.settings.enabledIslamicEventReminders[event.name] = newValue
                                if newValue {
                                    viewModel.scheduleIslamicEventReminder(for: event)
                                } else {
                                    viewModel.cancelIslamicEventReminder(for: event)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Événements Hégiriens")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
