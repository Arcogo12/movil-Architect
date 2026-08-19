import 'package:flutter/material.dart';
import 'package:movil_architect/models/home_project_models.dart';

class HomeStatusChip extends StatelessWidget {
  const HomeStatusChip({super.key, required this.status});

  final String status;

  Color _bg(ColorScheme scheme) {
    switch (status) {
      case 'completed':
      case 'active':
        return const Color(0xFF1B8A5A).withValues(alpha: 0.14);
      case 'in_progress':
        return const Color(0xFF1B4D8A).withValues(alpha: 0.14);
      case 'blocked':
      case 'canceled':
      case 'needs_correction':
        return const Color(0xFFD64545).withValues(alpha: 0.14);
      case 'needs_details':
      case 'on_hold':
        return const Color(0xFFD9A406).withValues(alpha: 0.16);
      default:
        return scheme.surfaceContainerHighest;
    }
  }

  Color _fg(ColorScheme scheme) {
    switch (status) {
      case 'completed':
      case 'active':
        return const Color(0xFF1B8A5A);
      case 'in_progress':
        return const Color(0xFF1B4D8A);
      case 'blocked':
      case 'canceled':
      case 'needs_correction':
        return const Color(0xFFD64545);
      case 'needs_details':
      case 'on_hold':
        return const Color(0xFFB07A00);
      default:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(scheme),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        homeProjectStatusLabel(status),
        style: TextStyle(
          color: _fg(scheme),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class HomeProjectCard extends StatelessWidget {
  const HomeProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final HomeProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (project.progressPercent / 100).clamp(0.0, 1.0);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HomeStatusChip(status: project.status),
                ],
              ),
              if (project.clientName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.clientName,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
              if (project.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.location,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Etapa ${project.currentStage}/9',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${project.progressPercent.round()}%',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: const Color(0xFF1B8A5A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
