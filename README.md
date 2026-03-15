# FitnessTimer

Minimalistische fitness timer met live hartslagweergave via Apple Watch.

## Features

- **Stopwatch** - Tel op tijdens je workout
- **Countdown Timer** - Presets: 30s, 1:00, 1:30, 2:00, 3:00, 5:00
- **Live hartslag** - Leest real-time hartslag van Apple Watch via HealthKit
- **Always-on display** - Scherm blijft aan tijdens je workout
- **Haptic feedback** - Trilsignaal wanneer countdown afloopt

## Setup in Xcode

1. Open Xcode → **File → New → Project → iOS App**
2. Product Name: `FitnessTimer`, Interface: **SwiftUI**, Language: **Swift**
3. Verwijder de gegenereerde `ContentView.swift` en `FitnessTimerApp.swift`
4. Sleep alle bestanden uit de `FitnessTimer/` map in dit project naar je Xcode project
5. Ga naar je **Target → Signing & Capabilities → + Capability → HealthKit**
6. Ga naar **Target → Info** en controleer dat `NSHealthShareUsageDescription` aanwezig is
7. **Build & Run** op je iPhone

## Gebruik

1. Start een **workout op je Apple Watch** (bijv. via de standaard Workout-app)
2. Open **FitnessTimer** op je iPhone
3. De app vraagt om HealthKit-toestemming → geef toegang tot hartslagdata
4. Je live hartslag verschijnt bovenaan het scherm
5. Gebruik de timer in stopwatch- of countdown-modus

## Kleurschema

Zwart (#0A0A0A) · Antraciet (#1A1A1A) · Donkergroen (#2D6A4F)
