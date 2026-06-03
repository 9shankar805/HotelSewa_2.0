import 'package:flutter/material.dart';
import 'floating_chatbot.dart';

class BaseLayout extends StatelessWidget {
  final Widget child;
  final bool showChatbot;
  final Color backgroundColor;
  final Color safeAreaColor;

  const BaseLayout({
    super.key,
    required this.child,
    this.showChatbot = true,
    this.backgroundColor = const Color(0xFFF8F8F8),
    this.safeAreaColor = const Color(0xFFE60023),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: safeAreaColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              child,
              if (showChatbot) const FloatingChatbot(),
            ],
          ),
        ),
      ),
    );
  }
}
