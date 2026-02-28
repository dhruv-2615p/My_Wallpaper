import 'package:flutter/material.dart';

/// Handy extension methods on BuildContext.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => mq.size.width;
  double get screenHeight => mq.size.height;
  EdgeInsets get padding => mq.padding;

  void showSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
