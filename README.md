# LaneKeeper

**Metric-based driving telemetry. Discipline > Chaos.**

LaneKeeper is a Flutter-based mobile application that helps drivers improve their safety and driving habits by analyzing phone sensor data. It calculates a "Rule Integrity Score" for every trip based on speed discipline, braking/acceleration smoothness, and lateral stability.

## Features

- **Automatic Trip Detection**: Starts recording when speed exceeds 8 km/h and stops when stationary.
- **Privacy First**: No camera, no microphone. Active only when driving.
- **Scoring Engine**: Detailed breakdown of driving performance (Speed, Stability, Patience).
- **Weekly Insights**: Track your improvement over time.
- **City Leaderboards**: Compare your score with others in your city (Coming Soon).

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / Xcode
- A Firebase Project

### 2. Firebase Configuration
This project relies on Firebase for Authentication and Database.

1.  Create a project in the [Firebase Console](https://console.firebase.google.com/).
2.  Add an **Android** app:
    - Package name: `com.lanekeeper`
    - Download `google-services.json` and place it in `android/app/`.
3.  Add an **iOS** app:
    - Bundle ID: `com.lanekeeper`
    - Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
4.  Enable **Authentication**:
    - Turn on **Google Sign-In**.
5.  Enable **Firestore Database**:
    - Start in **Test Mode** (or Production mode with rules allowing user access).
    - Deploy the following security rules:
      ```
      rules_version = '2';
      service cloud.firestore {
        match /databases/{database}/documents {
          match /users/{userId} {
            allow read, write: if request.auth != null && request.auth.uid == userId;
            match /trips/{tripId} {
               allow read, write: if request.auth != null && request.auth.uid == userId;
            }
          }
        }
      }
      ```

### 3. Running the App
```bash
flutter pub get
flutter run
```

## Testing Telemetry

Since you cannot drive while developing at your desk, LaneKeeper includes a **Developer Simulation Mode**.

1.  Login to the app.
2.  On the Home Screen, tap **"Simulate Trip"**.
3.  The app will inject mock GPS and Sensor data:
    - Accelerates to 30 km/h.
    - Cruises for a few seconds.
    - Performs a "Harsh Brake" event.
    - Stops.
4.  Watch the "Driving Mode" screen appear and then disappear.
5.  Check your updated Weekly Score on the Home Screen.

## Folder Structure
- `lib/core`: Theme, Constants.
- `lib/features`:
    - `auth`: Google Sign-In & Onboarding.
    - `telemetry`: Sensors & Location logic.
    - `scoring`: Mathematical models for driver scoring.
- `lib/ui`: Main screens.

## Tech Stack
- Flutter & Dart
- Firebase (Auth, Firestore)
- Riverpod (State Management)
- Geolocator & Sensors Plus
# lane-keeper
