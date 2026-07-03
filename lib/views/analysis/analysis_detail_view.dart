import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/models/analysis_models.dart';
import 'package:movil_architect/views/shared/app_states.dart';

class AnalysisDetailView extends StatelessWidget {
  const AnalysisDetailView({super.key, required this.item});

  final AnalysisSummary item;

  @override
  Widget build(BuildContext context) {
    final date = item.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt!.toLocal())
        : 'Sin fecha';

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppBar(
        backgroundColor: AppColors.dashboardSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: const Text(
          'Detalle del análisis',
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.filename,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(date, style: const TextStyle(color: AppColors.muted)),
                if (item.userPrompt != null && item.userPrompt!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Instrucción: ${item.userPrompt}',
                    style: const TextStyle(color: AppColors.ink),
                  ),
                ],
                const SizedBox(height: 16),
                AnalysisCountsRow(counts: item.counts),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
