import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/login_controller.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/views/dashboard/dashboard_view.dart';
import 'package:movil_architect/views/login/server_connection_view.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';
import 'package:movil_architect/views/register/register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginController _controller;
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final url = await AppServices.instance.settingsStorage.getServerUrl();
    if (!mounted) return;
    setState(() => _serverUrl = url);
  }

  Future<void> _openServerConnection() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ServerConnectionView(),
      ),
    );
    if (saved == true) {
      await _loadServerUrl();
    }
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

  String get _serverHint {
    if (_serverUrl.isEmpty) return 'Sin servidor configurado';
    final clean = _serverUrl
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
    if (clean.length <= 36) return clean;
    return '${clean.substring(0, 18)}…${clean.substring(clean.length - 14)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _openServerConnection,
                      icon: const Icon(Icons.dns_outlined, size: 18),
                      label: const Text('Servidor'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.iosBlue,
                      ),
                    ),
                  ),
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
                  Material(
                    color: AppColors.loginFieldFill,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _openServerConnection,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.link_rounded,
                              size: 22,
                              color: AppColors.iosBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Conectar al servidor',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _serverHint,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
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
