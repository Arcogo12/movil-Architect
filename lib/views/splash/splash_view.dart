import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/splash_controller.dart';
import 'package:movil_architect/views/dashboard/dashboard_view.dart';
import 'package:movil_architect/views/login/login_view.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';
import 'package:movil_architect/views/shared/app_states.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashController();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _controller.bootstrap();
    if (!mounted) return;

    switch (_controller.status) {
      case SplashStatus.readyDashboard:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const DashboardView()),
        );
      case SplashStatus.readyLogin:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const LoginView()),
        );
      case SplashStatus.serverError:
      case SplashStatus.loading:
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.status == SplashStatus.loading) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SplashBrandMark(),
                SizedBox(height: 32),
                AppLoadingView(message: 'Conectando con el servidor...'),
              ],
            );
          }

          if (_controller.status == SplashStatus.serverError) {
            return AppErrorView(
              message: _controller.errorMessage ??
                  'No se pudo conectar al servidor',
              onRetry: _bootstrap,
              retryLabel: 'Reintentar',
            );
          }

          return const AppLoadingView();
        },
      ),
    );
  }
}

/// Logo de arranque: aparece con fade y escala al abrir la app.
class _SplashBrandMark extends StatefulWidget {
  const _SplashBrandMark();

  @override
  State<_SplashBrandMark> createState() => _SplashBrandMarkState();
}

class _SplashBrandMarkState extends State<_SplashBrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: const LoginAppMark(),
      ),
    );
  }
}
