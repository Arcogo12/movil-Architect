import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/profile_controller.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/utils/app_notifications.dart';
import 'package:movil_architect/views/login/login_view.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';
import 'package:movil_architect/views/shared/app_states.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _avatarUrl() {
    final url = _controller.user?.avatarUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${AppServices.instance.apiClient.dio.options.baseUrl}$url';
  }

  void _showFeedback(bool ok) {
    if (ok && _controller.successMessage != null) {
      AppNotifications.success(context, _controller.successMessage!);
    } else if (_controller.errorMessage != null) {
      AppNotifications.error(context, _controller.errorMessage!);
    }
  }

  Future<void> _saveName() async {
    final ok = await _controller.saveName();
    if (!mounted) return;
    _showFeedback(ok);
  }

  Future<void> _savePassword() async {
    final ok = await _controller.savePassword();
    if (!mounted) return;
    _showFeedback(ok);
  }

  Future<void> _pickAvatar() async {
    final ok = await _controller.pickAndUploadAvatar();
    if (!mounted) return;
    _showFeedback(ok);
  }

  Future<void> _removeAvatar() async {
    final ok = await _controller.removeAvatar();
    if (!mounted) return;
    _showFeedback(ok);
  }

  Future<void> _delete() async {
    final user = _controller.user;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.hasPassword
                  ? 'Escribe tu contraseña para confirmar.'
                  : 'Escribe tu correo (${user.email}) para confirmar.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller.confirmDeleteController,
              obscureText: user.hasPassword,
              decoration: InputDecoration(
                hintText: user.hasPassword ? 'Contraseña' : 'Correo',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!await _controller.deleteAccount()) {
      if (mounted && _controller.errorMessage != null) {
        AppNotifications.error(context, _controller.errorMessage!);
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoadingProfile) {
            return const AppLoadingView(message: 'Cargando perfil...');
          }

          final user = _controller.user;
          final avatar = _avatarUrl();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _controller.isUpdatingAvatar ? null : _pickAvatar,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage:
                        avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(
                            (user?.fullName.isNotEmpty == true
                                    ? user!.fullName[0]
                                    : user?.email[0] ?? 'U')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    _controller.isUpdatingAvatar ? null : _pickAvatar,
                child: Text(
                  _controller.isUpdatingAvatar
                      ? 'Actualizando foto...'
                      : 'Cambiar foto',
                ),
              ),
              if (avatar != null)
                TextButton(
                  onPressed:
                      _controller.isUpdatingAvatar ? null : _removeAvatar,
                  child: const Text('Quitar foto'),
                ),
              const SizedBox(height: 16),
              LoginPillField(
                controller: _controller.nameController,
                hint: 'NOMBRE',
              ),
              const SizedBox(height: 12),
              LoginPrimaryButton(
                label: 'Guardar nombre',
                isLoading: _controller.isSavingName,
                onPressed: _saveName,
              ),
              const SizedBox(height: 28),
              Text(
                user?.hasPassword == false
                    ? 'Crea una contraseña (cuenta Google)'
                    : 'Cambiar contraseña',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              if (user?.hasPassword != false)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LoginPillField(
                    controller: _controller.currentPasswordController,
                    hint: 'CONTRASEÑA ACTUAL',
                    obscureText: true,
                    autocorrect: false,
                  ),
                ),
              LoginPillField(
                controller: _controller.newPasswordController,
                hint: 'NUEVA CONTRASEÑA',
                obscureText: true,
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              LoginPrimaryButton(
                label: 'Actualizar contraseña',
                isLoading: _controller.isSavingPassword,
                onPressed: _savePassword,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _controller.isDeletingAccount ? null : _delete,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD64545),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD64545),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _controller.isDeletingAccount
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Eliminar cuenta'),
              ),
            ],
          );
        },
      ),
    );
  }
}
