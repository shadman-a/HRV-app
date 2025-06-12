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

    override init() {
        super.init()
        locationManager.delegate = self
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

        // Placeholder queries; real implementations would query HealthKit
        let hrv = "--" // Query HRV from HealthKit
        newPoints.append(DataPoint(title: "HRV", value: hrv, timestamp: now))

        let restingHR = "--" // Query resting HR
        newPoints.append(DataPoint(title: "Resting HR", value: restingHR, timestamp: now))

        let sleep = "--" // Query sleep duration
        newPoints.append(DataPoint(title: "Sleep", value: sleep, timestamp: now))

        let mindful = "--" // Query mindful minutes
        newPoints.append(DataPoint(title: "Mindful Minutes", value: mindful, timestamp: now))

        let steps = "--" // Query step count
        newPoints.append(DataPoint(title: "Steps", value: steps, timestamp: now))

        let energy = "--" // Query active energy
        newPoints.append(DataPoint(title: "Active Energy", value: energy, timestamp: now))

        await MainActor.run { self.dataPoints = newPoints }
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
