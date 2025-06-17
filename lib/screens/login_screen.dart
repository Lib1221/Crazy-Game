import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme/game_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: GameTheme.spacingXXL),
                        // Game Logo
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(GameTheme.spacingL),
                            decoration: BoxDecoration(
                              gradient: GameTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(
                                  GameTheme.borderRadiusExtraLarge),
                              boxShadow: [
                                BoxShadow(
                                  color: GameTheme.accentColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sports_esports,
                              size: 64,
                              color: GameTheme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: GameTheme.spacingXXL),
                        // Welcome Text
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(GameTheme.spacingM),
                          decoration: BoxDecoration(
                            color: GameTheme.surfaceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                GameTheme.borderRadiusLarge),
                            border: Border.all(
                              color: GameTheme.accentColor.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: GameTheme.titleStyle.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: GameTheme.accentColor
                                          .withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: GameTheme.spacingS),
                              Text(
                                'Ready to continue your adventure?',
                                style: GameTheme.subtitleStyle.copyWith(
                                  fontSize: 16,
                                  color: GameTheme.textColor.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: GameTheme.spacingXXL),

                        // Login Form
                        Container(
                          padding: const EdgeInsets.all(GameTheme.spacingL),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                GameTheme.surfaceColor.withOpacity(0.8),
                                GameTheme.surfaceColor.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                                GameTheme.borderRadiusLarge),
                            boxShadow: [
                              BoxShadow(
                                color: GameTheme.accentColor.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: GameTheme.accentColor.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              Container(
                                decoration: BoxDecoration(
                                  color: GameTheme.backgroundColor
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(
                                      GameTheme.borderRadiusMedium),
                                  border: Border.all(
                                    color:
                                        GameTheme.accentColor.withOpacity(0.2),
                                  ),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelStyle: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                    hintStyle: const TextStyle(
                                      color: Colors.black38,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: GameTheme.accentColor),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(
                                        GameTheme.spacingM),
                                  ),
                                ),
                              ),
                              const SizedBox(height: GameTheme.spacingM),
                              // Password Field
                              Container(
                                decoration: BoxDecoration(
                                  color: GameTheme.backgroundColor
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(
                                      GameTheme.borderRadiusMedium),
                                  border: Border.all(
                                    color:
                                        GameTheme.accentColor.withOpacity(0.2),
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelStyle: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                    hintStyle: const TextStyle(
                                      color: Colors.black38,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: GameTheme.accentColor),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(
                                        GameTheme.spacingM),
                                  ),
                                ),
                              ),
                              const SizedBox(height: GameTheme.spacingL),
                              // Login Button
                              Obx(() => Container(
                                    decoration: BoxDecoration(
                                      gradient: GameTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(
                                          GameTheme.borderRadiusMedium),
                                      boxShadow: [
                                        BoxShadow(
                                          color: GameTheme.accentColor
                                              .withOpacity(0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _authController.isLoading.value
                                          ? null
                                          : () async {
                                              final success =
                                                  await _authController.login(
                                                _emailController.text,
                                                _passwordController.text,
                                              );
                                              if (success) {
                                                Get.offAllNamed('/chats');
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.all(
                                            GameTheme.spacingM),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              GameTheme.borderRadiusMedium),
                                        ),
                                      ),
                                      child: _authController.isLoading.value
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        GameTheme.textColor),
                                              ),
                                            )
                                          : const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: GameTheme.textColor,
                                              ),
                                            ),
                                    ),
                                  )),
                              const SizedBox(height: GameTheme.spacingM),
                              // Sign Up Link
                              TextButton(
                                onPressed: () => Get.offAllNamed('/signup'),
                                child: Text(
                                  'Don\'t have an account? Sign Up',
                                  style: TextStyle(
                                    color: GameTheme.accentColor,
                                    fontSize: 14,
                                  ),
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
      ..color = GameTheme.accentColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw grid pattern
    for (int i = 0; i < size.width; i += 20) {
      for (int j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }

    // Draw glowing orbs
    final orbPaint = Paint()
      ..color = GameTheme.accentColor.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.1,
      orbPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.15,
      orbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
