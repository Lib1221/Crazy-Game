import 'package:get/get.dart';
import 'package:crazygame/screens/splash_screen.dart';
import 'package:crazygame/screens/auth/login_screen.dart';
import 'package:crazygame/screens/auth/register_screen.dart';
import 'package:crazygame/screens/home/home_screen.dart';
import 'package:crazygame/screens/game/game_room_screen.dart';
import 'package:crazygame/screens/game/game_lobby_screen.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: Routes.GAME_LOBBY,
      page: () => const GameLobbyScreen(),
    ),
    GetPage(
      name: Routes.GAME_ROOM,
      page: () => const GameRoomScreen(),
    ),
  ];
} 