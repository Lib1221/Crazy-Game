class AppConfig {
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://api.crazygame.com',
  );

  static const int reconnectAttempts = 3;
  static const Duration reconnectDelay = Duration(seconds: 2);

  static String getGameWebSocketUrl(String roomId) {
    return '$wsBaseUrl/game/$roomId';
  }
}
