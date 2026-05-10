# 📱 HD Status — Flutter App (PureStatus Clone)

A Flutter app that compresses photos & videos for crystal-clear WhatsApp Status uploads, just like PureStatus.

---

## 🧠 How It Works

WhatsApp re-compresses any video/photo before uploading it as a Status, resulting in blurry output.

**HD Status** pre-compresses your media to *just below* WhatsApp's internal threshold using FFmpeg:
- **Videos**: Re-encoded to H.264 at ~3500 kbps (WhatsApp's limit is ~3800 kbps)
- **Photos**: Optimized to high-quality JPEG (92%) without resizing
- **Split**: Videos over 30 seconds are cut into 30-second parts (WhatsApp Status limit)

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── media_item.dart          # Data model for media
├── screens/
│   ├── splash_screen.dart       # Splash/loading screen
│   ├── home_screen.dart         # Main UI screen
│   └── home_controller.dart     # GetX state management
├── services/
│   ├── compression_service.dart # FFmpeg video/image compression
│   └── share_service.dart       # WhatsApp sharing logic
├── widgets/
│   └── media_card.dart          # Media item card UI
└── utils/
    └── app_theme.dart           # Dark/light theme colors
```

---

## 🚀 Setup Instructions

### 1. Prerequisites
- Flutter SDK ≥ 3.0.0 installed
- Android Studio or Xcode (for iOS builds)
- A physical device or emulator

### 2. Clone / Copy Project
```bash
# Copy this folder to your workspace
cd your_workspace
# Open in VSCode:
code purestatus_clone
```

### 3. Create Assets Folders
```bash
mkdir -p assets/images assets/icons assets/animations
touch assets/images/.gitkeep assets/icons/.gitkeep assets/animations/.gitkeep
```

### 4. Install Dependencies
```bash
flutter pub get
```

### 5. Android Setup
- Min SDK: **21** (Android 5.0)
- Target SDK: **34**

In `android/app/build.gradle`, make sure:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

Also add the `file_paths.xml` for FileProvider:
- Create: `android/app/src/main/res/xml/file_paths.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="." />
    <cache-path name="cache" path="." />
    <files-path name="files" path="." />
</paths>
```

### 6. iOS Setup
- Min iOS: **12.0**

In `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

Run:
```bash
cd ios && pod install && cd ..
```

### 7. Run the App
```bash
# Debug run
flutter run

# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build iOS IPA
flutter build ipa --release
```

---

## 🔑 Key Dependencies

| Package | Purpose |
|---|---|
| `ffmpeg_kit_flutter_min_gpl` | Core video compression using FFmpeg |
| `flutter_image_compress` | Photo compression |
| `image_picker` | Pick from gallery |
| `share_plus` | Share to WhatsApp |
| `video_player` | Video thumbnail preview |
| `get` | State management (GetX) |
| `percent_indicator` | Compression progress bar |

---

## ⚙️ Compression Settings (Tunable)

In `lib/services/compression_service.dart`:

```dart
static const int _targetVideoBitrate = 3500;  // kbps — raise/lower for quality
static const int _targetAudioBitrate = 128;   // kbps audio
static const int _photoQuality = 92;          // 0-100 JPEG quality
static const int _maxStatusDuration = 30;     // WhatsApp status limit (seconds)
```

**Tip:** If quality is still degraded, try lowering `_targetVideoBitrate` to `3200`.

---

## 📲 WhatsApp Sharing

- **Android**: Uses system share sheet targeting WhatsApp
- **iOS**: Uses native system share sheet → user selects WhatsApp

After tapping **"Share to WhatsApp"**, WhatsApp opens and you tap **"My Status"** to upload.

---

## 🛠 Troubleshooting

| Problem | Fix |
|---|---|
| `ffmpeg_kit` build error on iOS | Run `pod install` in `/ios` folder |
| Permission denied on Android 13+ | Grant `READ_MEDIA_VIDEO` and `READ_MEDIA_IMAGES` |
| Video not compressing | Ensure input video is not already compressed/low quality |
| Share not opening WhatsApp | Check WhatsApp is installed; use system share sheet to select it |

---

## 📌 Notes
- Do NOT edit the compressed video after exporting — it will re-trigger WhatsApp's compression
- Always use **high-quality original videos** as input for best results
- Vertical videos (9:16) look best on WhatsApp Status
