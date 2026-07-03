import 'package:flutter/material.dart';
import 'package:movil_architect/core/theme/app_colors.dart';

class PhoneShell extends StatelessWidget {
  const PhoneShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.phoneFrame,
        borderRadius: BorderRadius.circular(42),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(borderRadius: BorderRadius.circular(34), child: child),
    );
  }
}
