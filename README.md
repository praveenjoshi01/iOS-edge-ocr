# iOS Edge OCR

Offline OCR iOS app using on-device SmolVLM2 inference via Edge-Veda runtime with Metal GPU acceleration.

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cd ios && pod install && cd ..
flutter run --release
```
