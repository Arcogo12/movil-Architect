import 'package:flutter/material.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/core/utils/image_utils.dart';
import 'package:movil_architect/models/analysis_models.dart';
import 'package:movil_architect/views/dashboard/dashboard_view.dart';
import 'package:movil_architect/views/shared/app_states.dart';

class AnalysisResultsView extends StatelessWidget {
  const AnalysisResultsView({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final tone = result.verdict.tone;
    final color = verdictColor(tone);

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppBar(
        backgroundColor: AppColors.dashboardSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: const Text(
          'Resultado',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(verdictIcon(tone), color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        result.verdict.headline,
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (result.verdict.detail.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    result.verdict.detail,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnalysisCountsRow(counts: result.counts),
          const SizedBox(height: 16),
          if (result.imageBase64 != null && result.imageBase64!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                decodeBase64Image(result.imageBase64!),
                fit: BoxFit.contain,
              ),
            ),
          if (result.issues.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Incidencias',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...result.issues.map(
              (issue) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    verdictIcon(issue.severity),
                    color: verdictColor(issue.severity),
                  ),
                  title: Text(issue.title),
                  subtitle: issue.detail.isNotEmpty ? Text(issue.detail) : null,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (result.chatId != null && result.chatId!.isNotEmpty)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => DashboardView(
                      initialChatId: result.chatId,
                    ),
                  ),
                  (_) => false,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D8A),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Ver conversación'),
            ),
          if (result.chatId != null && result.chatId!.isNotEmpty)
            const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const DashboardView()),
                (_) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Volver al Dashboard'),
          ),
        ],
      ),
    );
  }
}
