import Foundation
import HealthKit

@MainActor
class HeartRateManager: ObservableObject {
    @Published var currentBPM: Int?
    @Published var isAuthorized = false
    @Published var authorizationError: String?

    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "HealthKit is niet beschikbaar op dit apparaat"
            return
        }

        let typesToRead: Set<HKObjectType> = [heartRateType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.startHeartRateQuery()
                } else {
                    self?.authorizationError = error?.localizedDescription ?? "Geen toegang tot hartslag"
                }
            }
        }
    }

    func startHeartRateQuery() {
        stopHeartRateQuery()

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        // First, get the most recent heart rate sample
        let mostRecentQuery = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            DispatchQueue.main.async {
                self?.currentBPM = bpm
            }
        }
        healthStore.execute(mostRecentQuery)

        // Then, start an anchored query for live updates
        let anchorQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        anchorQuery.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        healthStore.execute(anchorQuery)
        heartRateQuery = anchorQuery
    }

    func stopHeartRateQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample],
              let mostRecent = heartRateSamples.last else { return }

        let bpm = Int(mostRecent.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
        DispatchQueue.main.async { [weak self] in
            self?.currentBPM = bpm
        }
    }
}
