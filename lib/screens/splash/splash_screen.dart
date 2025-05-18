import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/screens/splash/components/logo_animation.dart';
import 'package:crazygame/screens/splash/components/loading_indicator.dart';
import 'package:crazygame/screens/splash/components/version_info.dart';
import 'package:crazygame/routes/app_pages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _fadeController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 3));

    // Navigate to the appropriate screen based on authentication state
    // For now, we'll just navigate to the login screen
    Get.offAllNamed(Routes.LOGIN);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with responsive sizing
                      SizedBox(
                        width:
                            isSmallScreen ? size.width * 0.4 : size.width * 0.3,
                        height:
                            isSmallScreen ? size.width * 0.4 : size.width * 0.3,
                        child: const LogoAnimation(),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 48),
                      // Loading indicator with responsive sizing
                      SizedBox(
                        width: isSmallScreen ? 32 : 48,
                        height: isSmallScreen ? 32 : 48,
                        child: const LoadingIndicator(),
                      ),
                    ],
                  ),
                ),
              ),
              // Version info at bottom
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: VersionInfo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
