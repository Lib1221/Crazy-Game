# Crazy Game

A real-time multiplayer card game built with Flutter and Firebase.

## Features
- Real-time group chat and game rooms
- Turn-based card game logic
- User authentication and profiles
- Leaderboards and achievements
- Themed UI with GameTheme

## Getting Started

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install)
- [Firebase Project](https://firebase.google.com/)

### Setup
1. Clone the repository:
   ```sh
   git clone <your-repo-url>
   cd crazygame
   ```
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Set up Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.
   - Configure Firebase in your project as per the [FlutterFire docs](https://firebase.flutter.dev/docs/overview/).
4. Run the app:
   ```sh
   flutter run
   ```

## Project Structure
- `lib/screens/` - UI screens
- `lib/services/` - Business logic and Firebase services
- `lib/theme/` - App theming
- `lib/controllers/` - State management

## Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Create a new Pull Request

## License
MIT
