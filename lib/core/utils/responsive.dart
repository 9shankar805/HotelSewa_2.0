import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;
  
  static bool isMobile(BuildContext context) => width(context) < 600;
  static bool isTablet(BuildContext context) => width(context) >= 600 && width(context) < 1024;
  static bool isDesktop(BuildContext context) => width(context) >= 1024;
  
  static double sp(BuildContext context, double size) {
    final scale = width(context) / 375;
    return size * scale;
  }
  
  static double wp(BuildContext context, double percentage) => width(context) * percentage / 100;
  static double hp(BuildContext context, double percentage) => height(context) * percentage / 100;
}
