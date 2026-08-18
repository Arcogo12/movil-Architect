import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movil_architect/controllers/settings_controller.dart';
import 'package:movil_architect/core/config/app_config.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';

/// Pantalla para configurar la URL del backend (emulador / ngrok / LAN)
/// sin necesidad de regenerar la APK.
class ServerConnectionView extends StatefulWidget {
  const ServerConnectionView({super.key});

  @override
  State<ServerConnectionView> createState() => _ServerConnectionViewState();
}

class _ServerConnectionViewState extends State<ServerConnectionView> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPreset(String url) {
    _controller.urlController.text = url;
    _controller.urlController.selection = TextSelection.collapsed(
      offset: url.length,
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _applyPreset(text);
  }

  Future<void> _save() async {
    final ok = await _controller.save();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servidor guardado. Ya puedes iniciar sesión.'),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Conectar al servidor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
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
                  const Icon(
                    Icons.dns_outlined,
                    size: 56,
                    color: AppColors.iosBlue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'URL del backend',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'En emulador Android usa 10.0.2.2 (tu PC). '
                    'En teléfono físico pega ngrok o Cloudflare.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.phone_android, size: 18),
                        label: const Text('Emulador'),
                        onPressed: () =>
                            _applyPreset(AppConfig.defaultEmulatorUrl),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.computer, size: 18),
                        label: const Text('Localhost'),
                        onPressed: () =>
                            _applyPreset(AppConfig.defaultLocalUrl),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.cloud_outlined, size: 18),
                        label: const Text('Túnel'),
                        onPressed: () =>
                            _applyPreset(AppConfig.sharedNgrokUrl),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LoginPillField(
                    controller: _controller.urlController,
                    hint: 'HTTP://10.0.2.2:8000',
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    onSubmitted: (_) => _save(),
                    suffix: GestureDetector(
                      onTap: _pasteFromClipboard,
                      child: const Icon(
                        Icons.content_paste_rounded,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Emulador: ${AppConfig.defaultEmulatorUrl}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  if (_controller.errorMessage != null) ...[
                    const SizedBox(height: 14),
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
                  if (_controller.successMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _controller.successMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1B8A5A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _controller.isTesting
                        ? null
                        : _controller.testConnection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.iosBlue,
                      side: const BorderSide(color: AppColors.iosBlue),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _controller.isTesting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Probar conexión',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                  const SizedBox(height: 12),
                  LoginPrimaryButton(
                    label: 'Guardar y continuar',
                    isLoading: _controller.isLoading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
