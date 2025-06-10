import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme/game_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _authController = Get.find<AuthController>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: CustomPaint(
              painter: GameBackgroundPainter(),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(GameTheme.spacingL),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: GameTheme.spacingXXL),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(GameTheme.spacingL),
                        decoration: BoxDecoration(
                          gradient: GameTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(GameTheme.borderRadiusExtraLarge),
                          boxShadow: GameTheme.glowShadow,
                        ),
                        child: const Icon(
                          Icons.sports_esports,
                          size: 64,
                          color: GameTheme.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: GameTheme.spacingXXL),
                    Text(
                      'Welcome Back!',
                      style: GameTheme.titleStyle,
                    ),
                    const SizedBox(height: GameTheme.spacingS),
                    Text(
                      'Ready to continue your adventure?',
                      style: GameTheme.subtitleStyle,
                    ),
                    const SizedBox(height: GameTheme.spacingXXL),

                    // Login Form
                    Container(
                      padding: const EdgeInsets.all(GameTheme.spacingL),
                      decoration: BoxDecoration(
                        color: GameTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(GameTheme.borderRadiusLarge),
                        boxShadow: GameTheme.defaultShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: GameTheme.textColor),
                            decoration: GameTheme.getInputDecoration(
                              label: 'Email',
                              prefixIcon: Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: GameTheme.spacingM),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: GameTheme.textColor),
                            decoration: GameTheme.getInputDecoration(
                              label: 'Password',
                              prefixIcon: Icons.lock_outline,
                            ),
                          ),
                          const SizedBox(height: GameTheme.spacingL),
                          Obx(() => ElevatedButton(
                                onPressed: _authController.isLoading.value
                                    ? null
                                    : () async {
                                        final success = await _authController.login(
                                          _emailController.text,
                                          _passwordController.text,
                                        );
                                        if (success) {
                                          Get.offAllNamed('/chats');
                                        }
                                      },
                                style: GameTheme.primaryButtonStyle,
                                child: Padding(
                                  padding: const EdgeInsets.all(GameTheme.spacingM),
                                  child: _authController.isLoading.value
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                GameTheme.textColor),
                                          ),
                                        )
                                      : const Text('Sign In'),
                                ),
                              )),
                          const SizedBox(height: GameTheme.spacingM),
                          TextButton(
                            onPressed: () => Get.toNamed('/signup'),
                            child: const Text(
                              'Don\'t have an account? Sign Up',
                              style: TextStyle(color: GameTheme.accentColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = GameTheme.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    // Draw main background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Draw decorative elements
    final dotPaint = Paint()
      ..color = GameTheme.accentColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = (i * 50.0) % size.width;
      final y = (i * 40.0) % size.height;
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
