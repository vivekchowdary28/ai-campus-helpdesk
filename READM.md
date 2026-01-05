# AI Campus Helpdesk (READM.md)

**Brief:** A Flutter app for handling campus helpdesk features.

## 🚀 Quick Start

Prerequisites
- Flutter installed (see https://flutter.dev)
- Xcode (for iOS builds)
- CocoaPods (for iOS pods)

Setup
1. flutter pub get
2. cd ios && pod install
3. flutter run -d <device>

## 🔧 iOS notes
- **Minimum iOS deployment target:** iOS 15.0 (updated to support Firebase plugins such as `firebase_auth`).
- If you see CocoaPods warnings about base configurations, either update your Xcode target base configs to include the generated `Pods-Runner` xcconfig or add it manually to your build settings.

## 🧪 Running
- Debug: `flutter run`
- Build (iOS): Open `ios/Runner.xcworkspace` in Xcode and build for the desired device.

## 💡 Tips
- If CI builds iOS, ensure the CI runner uses an Xcode version that supports iOS 15.0.

## 📄 Contributing
- File a branch + PR with a clear description and local verification steps.

---

If you want a more detailed README (screens, architecture, CI instructions), tell me what sections to add and I’ll update it.