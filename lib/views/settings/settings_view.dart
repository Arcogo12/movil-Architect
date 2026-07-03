import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/dashboard_controller.dart';
import 'package:movil_architect/controllers/settings_controller.dart';
import 'package:movil_architect/core/config/app_config.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/models/auth_models.dart';
import 'package:movil_architect/views/login/login_view.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, this.controller});

  final DashboardController? controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final DashboardController _dashboardController;
  late final SettingsController _settingsController;
  late final bool _ownsDashboardController;

  @override
  void initState() {
    super.initState();
    _ownsDashboardController = widget.controller == null;
    _dashboardController = widget.controller ?? DashboardController();
    _settingsController = SettingsController();
    _settingsController.load();
    if (_ownsDashboardController) {
      _dashboardController.load();
    }
  }

  @override
  void dispose() {
    _settingsController.dispose();
    if (_ownsDashboardController) {
      _dashboardController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveServer() async {
    final ok = await _settingsController.save();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servidor guardado correctamente')),
      );
    }
  }

  Future<void> _logout() async {
    await _dashboardController.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Text(
          'Ajustes',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _dashboardController,
          _settingsController,
        ]),
        builder: (context, _) {
          final subscription = _dashboardController.subscription;

          return RefreshIndicator(
            onRefresh: () => _dashboardController.load(refresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const _SectionTitle('Enterprise'),
                const SizedBox(height: 10),
                if (_dashboardController.state == DashboardState.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (subscription != null)
                  _EnterpriseCard(subscription: subscription)
                else
                  const _InfoCard(
                    message: 'No se pudo cargar la información del plan.',
                  ),
                const SizedBox(height: 28),
                const _SectionTitle('Apariencia'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SwitchListTile(
                    value: _settingsController.isDarkMode,
                    onChanged: _settingsController.setDarkMode,
                    title: Text(
                      'Modo oscuro',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _settingsController.isDarkMode
                          ? 'Tema oscuro activo'
                          : 'Tema claro activo',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    secondary: Icon(
                      _settingsController.isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: colorScheme.onSurface,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionTitle('Servidor'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'URL del backend',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Emulador Android: ${AppConfig.defaultEmulatorUrl}\n'
                        'Dispositivo físico: http://IP_DE_TU_PC:8000',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LoginPillField(
                        controller: _settingsController.urlController,
                        hint: 'URL DEL SERVIDOR',
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                      ),
                      if (_settingsController.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _settingsController.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      if (_settingsController.successMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _settingsController.successMessage!,
                          style: const TextStyle(color: Color(0xFF1B8A5A)),
                        ),
                      ],
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: _settingsController.isTesting
                            ? null
                            : _settingsController.testConnection,
                        child: _settingsController.isTesting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Probar conexión'),
                      ),
                      const SizedBox(height: 10),
                      LoginPrimaryButton(
                        label: 'Guardar servidor',
                        isLoading: _settingsController.isLoading,
                        onPressed: _saveServer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EnterpriseCard extends StatelessWidget {
  const _EnterpriseCard({required this.subscription});

  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    final plan = subscription.plan;
    final usage = subscription.usage;
    final limit = plan.analysesLimitMonthly;
    final progress = subscription.isUnlimited || limit == null || limit == 0
        ? null
        : (usage.analysesUsed / limit).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      subscription.status,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subscription.isUnlimited
                ? 'Análisis ilimitados este mes'
                : 'Análisis: ${usage.analysesUsed} / $limit',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.loginFieldFill,
                color: const Color(0xFF1B4D8A),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Máx. ${plan.maxFileMb} MB por archivo',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
      ),
    );
  }
}
