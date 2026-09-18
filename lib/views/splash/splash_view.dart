import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/splash_controller.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/views/dashboard/dashboard_view.dart';
import 'package:movil_architect/views/login/login_view.dart';
import 'package:movil_architect/views/shared/app_states.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final SplashController _controller;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _controller = SplashController();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _controller.bootstrap();
    if (!mounted || _navigating) return;

    final status = _controller.status;
    if (status == SplashStatus.readyDashboard) {
      _goTo(const DashboardView());
    } else if (status == SplashStatus.readyLogin) {
      _goTo(const LoginView());
    }
  }

  void _goTo(Widget page) {
    if (_navigating || !mounted) return;
    _navigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => page),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _splashContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/app_icon.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            cacheWidth: 240,
            cacheHeight: 240,
          ),
          const SizedBox(height: 28),
          const Text(
            'ARCHITECT',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.status == SplashStatus.serverError) {
            return AppErrorView(
              message: _controller.errorMessage ??
                  'No se pudo conectar al servidor',
              onRetry: () {
                _navigating = false;
                _bootstrap();
              },
              retryLabel: 'Reintentar',
            );
          }

          return _splashContent();
        },
      ),
    );
  }
}
