import Foundation
import HealthKit
import EventKit
import CoreLocation
import WeatherKit
import SwiftUI
import Combine

@MainActor
class AppDataManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private let eventStore = EKEventStore()
    private let locationManager = CLLocationManager()
    private let weatherService = WeatherService()

    @Published var dataPoints: [DataPoint] = []
    @Published private(set) var hrvHistory: [HRVRecord] = []

    override init() {
        super.init()
        locationManager.delegate = self
        loadHistory()
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "hrvHistory"),
           let records = try? JSONDecoder().decode([HRVRecord].self, from: data) {
            self.hrvHistory = records
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(hrvHistory) {
            UserDefaults.standard.set(data, forKey: "hrvHistory")
        }
    }

    func requestAuthorization() {
        // HealthKit types
        let healthTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: healthTypes) { success, error in
            if success {
                Task { await self.refreshHealthData() }
            }
        }

        // Calendar
        eventStore.requestAccess(to: .event) { granted, _ in
            if granted {
                Task { await self.refreshCalendar() }
            }
        }

        // Location
        locationManager.requestWhenInUseAuthorization()
    }

    func refreshAll() async {
        await refreshHealthData()
        await refreshWeather()
        await refreshCalendar()
    }

    private func refreshHealthData() async {
        var newPoints: [DataPoint] = []
        let now = Date()

        let hrv = await fetchMostRecentQuantity(
            identifier: .heartRateVariabilitySDNN,
            unit: .second(),
            format: { "\(Int($0 * 1000)) ms" }
        )
        newPoints.append(DataPoint(title: "HRV", value: hrv, timestamp: now))
        if let ms = Int(hrv.replacingOccurrences(of: " ms", with: "")) {
            hrvHistory.append(HRVRecord(date: now, value: ms))
            hrvHistory = hrvHistory.filter { $0.date > now.addingTimeInterval(-60*60*24*30) }
            saveHistory()
        }

        let restingHR = await fetchMostRecentQuantity(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            format: { "\(Int($0.rounded())) bpm" }
        )
        newPoints.append(DataPoint(title: "Resting HR", value: restingHR, timestamp: now))

        let sleep = await fetchSleepHours()
        newPoints.append(DataPoint(title: "Sleep", value: sleep, timestamp: now))

        let mindful = await fetchMindfulMinutes()
        newPoints.append(DataPoint(title: "Mindful Minutes", value: mindful, timestamp: now))

        let steps = await fetchSumQuantity(
            identifier: .stepCount,
            unit: .count(),
            format: { String(Int($0)) }
        )
        newPoints.append(DataPoint(title: "Steps", value: steps, timestamp: now))

        let energy = await fetchSumQuantity(
            identifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            format: { "\(Int($0)) kcal" }
        )
        newPoints.append(DataPoint(title: "Active Energy", value: energy, timestamp: now))

        await MainActor.run { self.dataPoints = newPoints }
    }

    private func fetchMostRecentQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        format: @escaping (Double) -> String
    ) async -> String {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return "--" }

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let sample = samples?.first as? HKQuantitySample {
                    let value = sample.quantity.doubleValue(for: unit)
                    continuation.resume(returning: format(value))
                } else {
                    continuation.resume(returning: "--")
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchSumQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        format: @escaping (Double) -> String
    ) async -> String {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return "--" }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                if let sum = stats?.sumQuantity() {
                    let value = sum.doubleValue(for: unit)
                    continuation.resume(returning: format(value))
                } else {
                    continuation.resume(returning: "--")
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchSleepHours() async -> String {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return "--" }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: "--")
                    return
                }
                let asleepValue = HKCategoryValueSleepAnalysis.asleep.rawValue
                let total = samples
                    .filter { $0.value == asleepValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let hours = total / 3600.0
                continuation.resume(returning: String(format: "%.1f h", hours))
            }
            healthStore.execute(query)
        }
    }

    private func fetchMindfulMinutes() async -> String {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return "--" }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: "--")
                    return
                }
                let total = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let minutes = Int(total / 60.0)
                continuation.resume(returning: "\(minutes) min")
            }
            healthStore.execute(query)
        }
    }

    private func refreshWeather() async {
        guard let location = locationManager.location else { return }
        do {
            let weather = try await weatherService.weather(for: location)
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .temperatureWithoutUnit
            let temp = formatter.string(from: weather.currentWeather.temperature)
            let conditions = weather.currentWeather.condition.description
            let weatherValue = "\(temp)° / \(conditions)"
            let now = Date()
            await MainActor.run {
                self.dataPoints.append(DataPoint(title: "Weather", value: weatherValue, timestamp: now))
            }
        } catch {
            // Handle errors silently for now
        }
    }

    private func refreshCalendar() async {
        let oneDay = Date().addingTimeInterval(60*60*24)
        let predicate = eventStore.predicateForEvents(withStart: Date(), end: oneDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
        if let nextEvent = events.first {
            await MainActor.run {
                self.dataPoints.append(DataPoint(title: "Next Event", value: nextEvent.title, timestamp: nextEvent.startDate))
            }
        }
    }
}

extension AppDataManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            Task { await self.refreshAll() }
        }
    }
}
