import 'package:flutter/material.dart';
import 'dart:async';

import 'package:go_router/go_router.dart';
import '../navigation/app_routes.dart';
import '../../core/constants/app_colors.dart';

class FloatingChatbot extends StatefulWidget {
  const FloatingChatbot({super.key});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  int _textIndex = 0;
  final List<String> _texts = ['Namaste', 'Chat with', 'HotelSewa'];
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_scaleController);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

    _textTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fadeController.reverse().then((_) {
        setState(() {
          _textIndex = (_textIndex + 1) % _texts.length;
        });
        _fadeController.forward();
      });
    });
  }

  void _handlePressDown() {
    _scaleController.animateTo(0.9, curve: Curves.easeOut);
  }

  void _handlePressUp() {
    _scaleController.animateTo(1.0, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 20,
      child: Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              constraints: const BoxConstraints(minWidth: 90),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE60023),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _texts[_textIndex],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * _pulseAnimation.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTapDown: (_) => _handlePressDown(),
              onTapUp: (_) => _handlePressUp(),
              onTapCancel: () => _handlePressUp(),
              onTap: () {
                context.push(AppRoutes.aiChat);
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.placeholder,
                      offset: Offset(0, 4),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Image.asset(
                    'assets/chatbot.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.chat_bubble,
                        size: 40,
                        color: Color(0xFFE60023),
                      );
                    },
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
