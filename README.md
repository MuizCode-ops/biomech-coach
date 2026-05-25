# Biomech Coach — Setup Guide

## Prerequisites
- Flutter SDK installed → https://docs.flutter.dev/get-started/install/windows
- Git installed → https://git-scm.com

---

## 1. First-Time Setup (Windows)

```powershell
# In c:\Users\Lenovo\Desktop\FYP\
.\setup.ps1
```

This will:
- Scaffold the Flutter project (`flutter create`)
- Create `assets/images/` directory
- Run `flutter pub get`

---

## 2. Run on Android (for development & testing)

Connect an Android phone with USB debugging, or open Android Studio and launch an emulator.

```powershell
flutter run
```

This is the fastest way to test the squat tracking pipeline before the iOS build.

---

## 3. Run on iPhone — Without a Mac (Codemagic)

Since you have an iPhone but no Mac, use **Codemagic** to build iOS in the cloud.

### Step-by-Step

#### A. Push to GitHub
```powershell
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/biomech-coach.git
git push -u origin main
```

#### B. Set up Codemagic
1. Go to → https://codemagic.io and sign up (free)
2. Click **"Add application"** → connect your GitHub account
3. Select the `biomech-coach` repository
4. Codemagic will auto-detect `codemagic.yaml`

#### C. Set up Code Signing (required for iPhone)
1. You need a free **Apple ID** (or paid Apple Developer account for TestFlight)
2. In Codemagic → **Teams → Integrations → Apple Developer Portal**
3. Connect your Apple ID
4. For free provisioning (sideloading): use **Ad Hoc** distribution

> **Free Apple ID**: You can install on up to 3 devices without paying $99/year.
> **Apple Developer ($99/yr)**: Allows TestFlight distribution.

#### D. Install the IPA on your iPhone
After Codemagic builds successfully:
- **With free Apple ID**: Download the `.ipa`, use [AltStore](https://altstore.io) or [Sideloadly](https://sideloadly.io) to install
- **With Developer account**: Distribute via TestFlight

---

## 4. Project Structure

```
FYP/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── constants/lift_thresholds.dart
│   ├── models/                      # Hive data models
│   ├── services/                    # AI, biomechanics, TTS, DB
│   ├── widgets/                     # Skeleton, angles, rep counter
│   └── screens/                     # Home, Camera, Summary, Journal
├── ios/Runner/Info.plist            # iOS permissions (camera, mic)
├── android/app/src/main/            # Android permissions
├── codemagic.yaml                   # Cloud iOS build config
├── setup.ps1                        # One-click setup
└── pubspec.yaml                     # Dependencies
```

---

## 5. How the App Works

1. **Home Screen** → Tap "Start Session" on the Squat card
2. **Camera Screen** → Front camera activates, ML Kit detects your pose
3. **Skeleton overlay** draws on your live feed in real-time
4. **Biomechanics engine** calculates hip & knee angles with `atan2`
5. **State machine** tracks: IDLE → LOWER → DEPTH ✓ → DRIVE UP → LOCKOUT ✓
6. **Valid reps** are counted only if hip angle < 90° (IPF standard)
7. **TTS coach** fires audio cues: *"Go deeper!"*, *"Back rounding!"*
8. **End Session** → Summary screen with form score chart
9. All data saved locally to **Hive** (no cloud, no account)

---

## 6. Dependencies

| Package | Purpose |
|:---|:---|
| `camera` | Live camera feed |
| `google_mlkit_pose_detection` | 33-landmark AI pose detection |
| `flutter_tts` | Text-to-speech coaching |
| `hive` + `hive_flutter` | On-device SQLite-like storage |
| `fl_chart` | Form score charts |
| `google_fonts` | Outfit typeface |
| `provider` | State management |

---

## 7. Known Constraints (from PRD)
- 2D tracking only (single camera)
- Requires good lighting
- Accuracy may drop with baggy clothing or occlusion
- iOS 14.0+ required
