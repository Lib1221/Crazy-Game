# Architecture

Crazy Game is a real-time multiplayer card game on Flutter with Firebase for auth, realtime state, chat, and leaderboards.

## Layers (`lib/`)

| Layer | Folder | Notes |
| ----- | ------ | ----- |
| Screens | `screens/` | splash, login, signup, chat list, chat, create group, my games, search user, leaderboard, achievements, edit profile, settings, appearance settings |
| Controllers | `controllers/` | Screen-level state and orchestration |
| Logic | `logic/` | Turn order, card rules, win conditions (pure Dart, testable) |
| Services | `services/` | `chat_service.dart`, `error_service.dart`, `game/` (game room CRUD and moves), `realtime/` (Firebase Realtime Database / Firestore listeners) |
| Models | `models/` | Player, room, card, message, achievement |
| Theme | `theme.dart`, `theme/` | `GameTheme` and palette switching |

## Realtime flow

```
Player action -> controller -> game service -> Firebase write
Firebase change -> realtime listener -> controller -> UI rebuild
```

- Every room has a single authoritative document; clients subscribe and render.
- Chat uses the same realtime channel per room or group.
- `database.rules.json` and `firebase.rules.json` define access rules; keep them in sync with model changes.
