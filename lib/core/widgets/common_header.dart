import 'package:flutter/material.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final bool showMenu;
  final bool showBack;
  final VoidCallback? onMenuPress;
  final VoidCallback? onBackPress;
  final IconData? rightIcon;
  final VoidCallback? onRightPress;

  const CommonHeader({
    super.key,
    this.title = 'HOTELSEWA',
    this.showMenu = false,
    this.showBack = false,
    this.onMenuPress,
    this.onBackPress,
    this.rightIcon,
    this.onRightPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: showMenu
                ? IconButton(
                    icon: const Icon(Icons.menu, size: 28, color: Color(0xFF333333)),
                    onPressed: onMenuPress,
                    padding: EdgeInsets.zero,
                  )
                : showBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back, size: 28, color: Color(0xFF333333)),
                        onPressed: onBackPress,
                        padding: EdgeInsets.zero,
                      )
                    : const SizedBox(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE60023),
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: rightIcon != null
                ? IconButton(
                    icon: Icon(rightIcon, size: 28, color: const Color(0xFF333333)),
                    onPressed: onRightPress,
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
