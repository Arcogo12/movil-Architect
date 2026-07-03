import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/login_controller.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/views/dashboard/dashboard_view.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';
import 'package:movil_architect/views/register/register_view.dart';
import 'package:movil_architect/views/settings/settings_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!await _controller.login()) return;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Configurar servidor',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsView(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: LoginAppMark()),
                  const SizedBox(height: 40),
                  const Text(
                    'Iniciar sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  LoginPillField(
                    controller: _controller.emailController,
                    hint: 'CORREO ELECTRÓNICO',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    onChanged: (_) => _controller.clearError(),
                  ),
                  const SizedBox(height: 14),
                  LoginPillField(
                    controller: _controller.passwordController,
                    hint: 'CONTRASEÑA',
                    obscureText: _controller.obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    onChanged: (_) => _controller.clearError(),
                    suffix: GestureDetector(
                      onTap: _controller.toggleObscurePassword,
                      child: Icon(
                        _controller.obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  if (_controller.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  LoginPrimaryButton(
                    label: 'Iniciar sesión',
                    isLoading: _controller.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                      ),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterView(),
                          ),
                        );
                      },
                      child: const Text('Crear cuenta'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const LoginSocialDivider(),
                  const SizedBox(height: 20),
                  LoginGoogleButton(onPressed: () {}),
                  const SizedBox(height: 32),
                  const LoginLegalFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
