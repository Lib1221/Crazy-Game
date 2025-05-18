import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/routes/app_pages.dart';
import 'package:crazygame/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crazygame/controllers/game_controller.dart';
import 'package:crazygame/controllers/settings_controller.dart';
import 'package:crazygame/services/websocket_service.dart';
import 'package:crazygame/services/voice_chat_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize services
  Get.put(WebSocketService());
  Get.put(VoiceChatService());

  // Initialize controllers
  Get.put(SettingsController());
  Get.put(GameController());

  runApp(const CrazyGameApp());
}

class CrazyGameApp extends StatelessWidget {
  const CrazyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Crazy Game',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
