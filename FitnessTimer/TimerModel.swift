import Foundation
import SwiftUI

enum TimerMode: String, CaseIterable {
    case stopwatch = "Stopwatch"
    case countdown = "Countdown"
}

struct TimerPreset: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let seconds: TimeInterval

    static let presets: [TimerPreset] = [
        TimerPreset(label: "0:30", seconds: 30),
        TimerPreset(label: "1:00", seconds: 60),
        TimerPreset(label: "1:30", seconds: 90),
        TimerPreset(label: "2:00", seconds: 120),
        TimerPreset(label: "3:00", seconds: 180),
        TimerPreset(label: "5:00", seconds: 300),
    ]

    static func == (lhs: TimerPreset, rhs: TimerPreset) -> Bool {
        lhs.seconds == rhs.seconds
    }
}

@MainActor
class TimerModel: ObservableObject {
    @Published var mode: TimerMode = .stopwatch
    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var countdownDuration: TimeInterval = 60
    @Published var countdownFinished = false

    private var timer: Timer?
    private var startDate: Date?
    private var accumulatedTime: TimeInterval = 0

    var displayTime: TimeInterval {
        switch mode {
        case .stopwatch:
            return elapsedTime
        case .countdown:
            return max(0, countdownDuration - elapsedTime)
        }
    }

    var formattedTime: String {
        let total = displayTime
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        let tenths = Int((total * 10).truncatingRemainder(dividingBy: 10))

        if mode == .stopwatch {
            return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
        } else {
            if total >= 60 {
                return String(format: "%d:%02d", minutes, seconds)
            } else {
                return String(format: "%02d.%d", seconds, tenths)
            }
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        countdownFinished = false
        startDate = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        accumulatedTime = elapsedTime
        startDate = nil
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        stop()
        elapsedTime = 0
        accumulatedTime = 0
        countdownFinished = false
    }

    func selectPreset(_ preset: TimerPreset) {
        reset()
        countdownDuration = preset.seconds
    }

    func setMode(_ newMode: TimerMode) {
        reset()
        mode = newMode
    }

    private func tick() {
        guard let startDate = startDate else { return }
        elapsedTime = accumulatedTime + Date().timeIntervalSince(startDate)

        if mode == .countdown && displayTime <= 0 && !countdownFinished {
            countdownFinished = true
            stop()
            triggerHaptic()
        }
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
