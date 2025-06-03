import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/controllers/game_controller.dart';

class ConnectionStatus extends StatelessWidget {
  final GameController controller = Get.find<GameController>();

  ConnectionStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return _StatusIndicator(
          icon: Icons.sync,
          message: 'Connecting...',
          color: Colors.blue,
          isAnimated: true,
        );
      }

      if (controller.isReconnecting) {
        return _StatusIndicator(
          icon: Icons.sync_problem,
          message: 'Reconnecting...',
          color: Colors.orange,
          onRetry: controller.retryConnection,
          isAnimated: true,
        );
      }

      if (!controller.isConnected) {
        return _StatusIndicator(
          icon: Icons.error_outline,
          message: 'Disconnected',
          color: Colors.red,
          onRetry: controller.retryConnection,
          showPulse: true,
        );
      }

      if (controller.error != null) {
        return _StatusIndicator(
          icon: Icons.error_outline,
          message: controller.error!,
          color: Colors.red,
          onRetry: controller.retryConnection,
          showPulse: true,
        );
      }

      return _StatusIndicator(
        icon: Icons.check_circle,
        message: 'Connected',
        color: Colors.green,
        showSuccessAnimation: true,
      );
    });
  }
}

class _StatusIndicator extends StatefulWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onRetry;
  final bool isAnimated;
  final bool showPulse;
  final bool showSuccessAnimation;

  const _StatusIndicator({
    required this.icon,
    required this.message,
    required this.color,
    this.onRetry,
    this.isAnimated = false,
    this.showPulse = false,
    this.showSuccessAnimation = false,
  });

  @override
  State<_StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<_StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isAnimated || widget.showPulse) {
      _controller.repeat(reverse: true);
    } else if (widget.showSuccessAnimation) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.color.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: widget.isAnimated ? _scaleAnimation.value : 1.0,
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.message,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onRetry,
                  child: const Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
