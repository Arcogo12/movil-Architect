import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/home_project_controller.dart';
import 'package:movil_architect/views/home_projects/create_home_project_view.dart';
import 'package:movil_architect/views/home_projects/home_project_detail_view.dart';
import 'package:movil_architect/views/home_projects/home_project_team_view.dart';
import 'package:movil_architect/views/home_projects/widgets/home_project_widgets.dart';
import 'package:movil_architect/views/shared/app_states.dart';

class HomeProjectsListView extends StatefulWidget {
  const HomeProjectsListView({super.key});

  @override
  State<HomeProjectsListView> createState() => _HomeProjectsListViewState();
}

class _HomeProjectsListViewState extends State<HomeProjectsListView> {
  late final HomeProjectsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeProjectsController();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateHomeProjectView()),
    );
    if (mounted) await _controller.load(refresh: true);
  }

  Future<void> _openDetail(String projectId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeProjectDetailView(projectId: projectId),
      ),
    );
    if (mounted) await _controller.load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Casa hogar',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Aceptar invitación',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AcceptInviteView()),
              );
            },
            icon: const Icon(Icons.mail_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo proyecto'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.state == HomeProjectsState.loading) {
            return const AppLoadingView(message: 'Cargando proyectos...');
          }
          if (_controller.state == HomeProjectsState.error) {
            return AppErrorView(
              message: _controller.errorMessage ?? 'Error al cargar',
              onRetry: () => _controller.load(),
            );
          }
          if (_controller.state == HomeProjectsState.empty) {
            return RefreshIndicator(
              onRefresh: () => _controller.load(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                  Icon(
                    Icons.home_work_outlined,
                    size: 56,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay proyectos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primer proyecto de vivienda\nunifamiliar en 9 etapas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _controller.load(refresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: _controller.projects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final project = _controller.projects[index];
                return HomeProjectCard(
                  project: project,
                  onTap: () => _openDetail(project.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
