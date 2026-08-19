import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/home_project_controller.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/core/utils/app_notifications.dart';
import 'package:movil_architect/models/home_project_models.dart';
import 'package:movil_architect/views/home_projects/home_project_detail_view.dart';

class AcceptInviteView extends StatefulWidget {
  const AcceptInviteView({super.key});

  @override
  State<AcceptInviteView> createState() => _AcceptInviteViewState();
}

class _AcceptInviteViewState extends State<AcceptInviteView> {
  final _tokenController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final token = _tokenController.text.trim();
    if (token.length < 8) {
      setState(() => _error = 'Ingresa un token válido.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final project =
          await AppServices.instance.homeProjectService.acceptInvite(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeProjectDetailView(projectId: project.id),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo aceptar la invitación.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aceptar invitación',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pega el token de invitación que recibiste por correo.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Token de invitación',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _accept,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Aceptar invitación'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeProjectTeamView extends StatelessWidget {
  const HomeProjectTeamView({super.key, required this.controller});

  final HomeProjectDetailController controller;

  Future<void> _invite(BuildContext context) async {
    final emailController = TextEditingController();
    var role = 'editor';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Invitar miembro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(role),
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'editor', child: Text('Editor')),
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                ],
                onChanged: (value) {
                  if (value != null) setLocal(() => role = value);
                },
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
              child: const Text('Invitar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) {
      emailController.dispose();
      return;
    }
    final status = await controller.inviteMember(
      email: emailController.text,
      role: role,
    );
    emailController.dispose();
    if (!context.mounted) return;
    final message = status ?? controller.actionError ?? 'No se pudo invitar';
    if (status == null || status == 'Sin permiso para invitar.') {
      AppNotifications.error(context, message);
    } else {
      AppNotifications.success(context, message);
    }
  }

  Future<void> _remove(
    BuildContext context,
    HomeProjectMember member,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar miembro'),
        content: Text('¿Quitar a ${member.fullName.isNotEmpty ? member.fullName : member.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await controller.removeMember(member.userId);
    if (!context.mounted) return;
    AppNotifications.result(
      context,
      ok: success,
      successMessage: 'Miembro eliminado',
      errorMessage: controller.actionError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final project = controller.project;
        final canManage = controller.permissions.canManageTeam;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Equipo',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
          ),
          floatingActionButton: canManage
              ? FloatingActionButton.extended(
                  onPressed: controller.busy ? null : () => _invite(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Invitar'),
                )
              : null,
          body: project == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => controller.load(refresh: true),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      Text(
                        canManage
                            ? 'Gestiona miembros del proyecto.'
                            : 'Solo lectura: puedes ver el equipo.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      if (project.members.isEmpty)
                        Text(
                          'Aún no hay miembros listados.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        )
                      else
                        for (final member in project.members) ...[
                          Material(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  ((member.fullName.isNotEmpty
                                              ? member.fullName
                                              : member.email)
                                          .trim()
                                          .isNotEmpty
                                      ? (member.fullName.isNotEmpty
                                              ? member.fullName
                                              : member.email)
                                          .trim()[0]
                                      : '?')
                                      .toUpperCase(),
                                ),
                              ),
                              title: Text(
                                member.fullName.isNotEmpty
                                    ? member.fullName
                                    : member.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${member.email}\n${homeProjectRoleLabel(member.role)}',
                              ),
                              isThreeLine: true,
                              trailing: canManage && !member.isOwner
                                  ? IconButton(
                                      tooltip: 'Quitar',
                                      onPressed: controller.busy
                                          ? null
                                          : () => _remove(context, member),
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                        color: Colors.redAccent,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

