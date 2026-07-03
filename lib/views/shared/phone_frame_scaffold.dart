import 'package:flutter/material.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/views/shared/phone_shell.dart';

class PhoneFrameScaffold extends StatelessWidget {
  const PhoneFrameScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: PhoneShell(child: child),
          ),
        ),
      ),
    );
  }
}