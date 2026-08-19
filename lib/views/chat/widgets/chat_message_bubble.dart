import 'package:flutter/material.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/core/utils/image_utils.dart';
import 'package:movil_architect/models/chat_models.dart';
import 'package:movil_architect/views/shared/app_states.dart';
import 'package:movil_architect/views/shared/markdown_text.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: message.isUser ? _UserBubble(message: message) : _AssistantBubble(message: message),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final content = message.content;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.filename != null && content.filename!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    content.filename!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (content.text != null && content.text!.isNotEmpty)
            Text(
              content.text!,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final content = message.content;
    final verdict = content.verdict;
    final toneColor = verdict != null ? verdictColor(verdict.tone) : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiReplyHeader(),
          const SizedBox(height: 10),
          if (verdict != null && verdict.headline.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(verdictIcon(verdict.tone), color: toneColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verdict.headline,
                    style: TextStyle(
                      color: toneColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (verdict.detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                verdict.detail,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
            const SizedBox(height: 10),
          ],
          if (content.stats != null) ...[
            AnalysisCountsRow(counts: content.stats!),
            const SizedBox(height: 10),
          ],
          if (content.imageBase64 != null && content.imageBase64!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                decodeBase64Image(content.imageBase64!),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (content.text != null && content.text!.isNotEmpty)
            MarkdownText(
              data: content.text!,
              style: const TextStyle(color: AppColors.ink, height: 1.45),
            ),
        ],
      ),
    );
  }
}

class AiReplyHeader extends StatelessWidget {
  const AiReplyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.dashboardIconBg,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Icon(
              Icons.auto_awesome,
              size: 12,
              color: AppColors.ink,
            ),
          ),
        ),
        SizedBox(width: 8),
   
      ],
    );
  }
}
