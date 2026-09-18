import 'package:flutter/material.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/core/utils/chat_attachment_cache.dart';
import 'package:movil_architect/core/utils/image_utils.dart';
import 'package:movil_architect/models/chat_models.dart';
import 'package:movil_architect/views/dashboard/widgets/dashboard_shell.dart';
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
        child: message.isUser
            ? _UserBubble(message: message)
            : _AssistantBubble(message: message),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final ChatMessage message;

  String? get _imageBase64 {
    final content = message.content;
    final fromContent = content.imageBase64;
    if (fromContent != null && fromContent.isNotEmpty) return fromContent;
    return ChatAttachmentCache.instance.get(content.filename);
  }

  @override
  Widget build(BuildContext context) {
    final content = message.content;
    final filename = content.filename;
    final cachedOrRemoteImage = _imageBase64;
    final canShowImage = cachedOrRemoteImage != null &&
        cachedOrRemoteImage.isNotEmpty &&
        (filename == null ||
            filename.isEmpty ||
            isPlanoImageFile(filename));
    final text = content.text?.trim();
    final hasText = text != null && text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canShowImage && cachedOrRemoteImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.memory(
                  decodeBase64Image(cachedOrRemoteImage),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0x33FFFFFF),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            if (filename != null && filename.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (hasText) const SizedBox(height: 10),
          ] else if (filename != null && filename.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    filename,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (hasText) const SizedBox(height: 8),
          ],
          if (hasText)
            Text(
              text,
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
