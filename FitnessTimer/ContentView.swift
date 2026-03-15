import SwiftUI

// MARK: - Colors

extension Color {
    static let appBackground = Color(red: 0.04, green: 0.04, blue: 0.04)       // #0A0A0A
    static let appCard = Color(red: 0.10, green: 0.10, blue: 0.10)             // #1A1A1A
    static let appCardLight = Color(red: 0.16, green: 0.16, blue: 0.16)        // #2A2A2A
    static let appGreen = Color(red: 0.176, green: 0.416, blue: 0.31)          // #2D6A4F
    static let appGreenLight = Color(red: 0.25, green: 0.57, blue: 0.42)       // #40916C
    static let appTextPrimary = Color(red: 0.88, green: 0.88, blue: 0.88)      // #E0E0E0
    static let appTextSecondary = Color(red: 0.42, green: 0.42, blue: 0.42)    // #6B6B6B
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var timerModel = TimerModel()
    @StateObject private var heartRateManager = HeartRateManager()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                // Heart Rate Section
                HeartRateDisplay(bpm: heartRateManager.currentBPM)

                Spacer().frame(height: 16)

                // Divider
                Rectangle()
                    .fill(Color.appCard)
                    .frame(height: 1)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 16)

                // Timer Display
                TimerDisplay(formattedTime: timerModel.formattedTime, isFinished: timerModel.countdownFinished)

                Spacer().frame(height: 32)

                // Controls
                TimerControls(timerModel: timerModel)

                Spacer().frame(height: 24)

                // Mode Picker
                ModePicker(timerModel: timerModel)

                Spacer().frame(height: 20)

                // Preset buttons (countdown only)
                if timerModel.mode == .countdown {
                    PresetGrid(timerModel: timerModel)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            heartRateManager.requestAuthorization()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            heartRateManager.stopHeartRateQuery()
        }
    }
}

// MARK: - Heart Rate Display

struct HeartRateDisplay: View {
    let bpm: Int?
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.appGreen)
                    .scaleEffect(heartScale)
                    .animation(
                        bpm != nil
                            ? .easeInOut(duration: bpm.map { 60.0 / Double($0) / 2 } ?? 0.5)
                                .repeatForever(autoreverses: true)
                            : .default,
                        value: heartScale
                    )
                    .onAppear { heartScale = 0.85 }
                    .onChange(of: bpm) { _ in heartScale = 0.85 }

                Text(bpm.map { "\($0)" } ?? "--")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                    .monospacedDigit()
            }

            Text("BPM")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .tracking(4)
        }
    }
}

// MARK: - Timer Display

struct TimerDisplay: View {
    let formattedTime: String
    let isFinished: Bool

    var body: some View {
        Text(formattedTime)
            .font(.system(size: 80, weight: .bold, design: .monospaced))
            .foregroundColor(isFinished ? .appGreenLight : .appTextPrimary)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}

// MARK: - Timer Controls

struct TimerControls: View {
    @ObservedObject var timerModel: TimerModel

    var body: some View {
        HStack(spacing: 24) {
            // Start / Stop button
            Button(action: {
                if timerModel.isRunning {
                    timerModel.stop()
                } else {
                    timerModel.start()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: timerModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                    Text(timerModel.isRunning ? "Stop" : "Start")
                        .font(.system(size: 22, weight: .semibold))
                }
                .foregroundColor(.appTextPrimary)
                .frame(width: 160, height: 60)
                .background(timerModel.isRunning ? Color.appCardLight : Color.appGreen)
                .cornerRadius(16)
            }

            // Reset button
            Button(action: {
                timerModel.reset()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                    .frame(width: 60, height: 60)
                    .background(Color.appCard)
                    .cornerRadius(16)
            }
        }
    }
}

// MARK: - Mode Picker

struct ModePicker: View {
    @ObservedObject var timerModel: TimerModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                Button(action: {
                    timerModel.setMode(mode)
                }) {
                    Text(mode.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(timerModel.mode == mode ? .appTextPrimary : .appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(timerModel.mode == mode ? Color.appCard : Color.clear)
                        .cornerRadius(12)
                }
            }
        }
        .background(Color.appBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appCard, lineWidth: 1)
        )
    }
}

// MARK: - Preset Grid

struct PresetGrid: View {
    @ObservedObject var timerModel: TimerModel

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(TimerPreset.presets) { preset in
                Button(action: {
                    timerModel.selectPreset(preset)
                }) {
                    Text(preset.label)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(
                            timerModel.countdownDuration == preset.seconds
                                ? .appTextPrimary
                                : .appTextSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            timerModel.countdownDuration == preset.seconds
                                ? Color.appGreen.opacity(0.3)
                                : Color.appCard
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    timerModel.countdownDuration == preset.seconds
                                        ? Color.appGreen
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
