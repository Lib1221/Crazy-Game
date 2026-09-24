# Setup

```bash
git clone https://github.com/Lib1221/Crazy-Game.git
cd Crazy-Game
flutter pub get
flutterfire configure
flutter run
```

Enable Authentication (email/password), Firestore, and Realtime Database in the Firebase console, then deploy the rules:

```bash
firebase deploy --only firestore:rules,database
```

Checks: `flutter analyze`, `flutter test`.

A compiled web build is published separately in [web-version-crazy-game](https://github.com/Lib1221/web-version-crazy-game).
