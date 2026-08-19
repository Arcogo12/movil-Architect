import 'package:movil_architect/models/analysis_models.dart';

class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messageCount,
  });

  final String id;
  final String title;
  final DateTime? updatedAt;
  final int messageCount;

  factory ChatSummary.fromJson(Map<String, dynamic> json) {
    return ChatSummary(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? 'Conversación',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      messageCount: json['message_count'] as int? ?? 0,
    );
  }
}

class MessageContent {
  const MessageContent({
    this.text,
    this.filename,
    this.analysisId,
    this.verdict,
    this.imageBase64,
    this.stats,
  });

  final String? text;
  final String? filename;
  final int? analysisId;
  final VerdictModel? verdict;
  final String? imageBase64;
  final AnalysisCounts? stats;

  factory MessageContent.fromJson(dynamic json) {
    if (json == null) return const MessageContent();
    if (json is String) return MessageContent(text: json);

    final map = json as Map<String, dynamic>;
    return MessageContent(
      text: map['text'] as String?,
      filename: map['filename'] as String?,
      analysisId: (map['analysis_id'] as num?)?.toInt(),
      verdict: map['verdict'] is Map<String, dynamic>
          ? VerdictModel.fromJson(map['verdict'] as Map<String, dynamic>)
          : null,
      imageBase64: map['image_base64'] as String?,
      stats: map['stats'] is Map<String, dynamic>
          ? AnalysisCounts.fromJson(map['stats'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String role;
  final MessageContent content;
  final DateTime? createdAt;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? 'user',
      content: MessageContent.fromJson(json['content']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class ChatDetail {
  const ChatDetail({
    required this.chat,
    required this.messages,
  });

  final ChatSummary chat;
  final List<ChatMessage> messages;

  factory ChatDetail.fromJson(Map<String, dynamic> json) {
    final chatJson = json['chat'] as Map<String, dynamic>? ?? {};
    return ChatDetail(
      chat: ChatSummary.fromJson(chatJson),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(),
    );
  }

  int? get lastAnalysisId {
    for (var i = messages.length - 1; i >= 0; i--) {
      final id = messages[i].content.analysisId;
      if (id != null) return id;
    }
    return null;
  }
}

class AskResponse {
  const AskResponse({this.chatId, this.text});

  final String? chatId;
  final String? text;

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    String? text = json['text'] as String? ??
        json['answer'] as String? ??
        json['message'] as String? ??
        json['markdown'] as String?;
    final content = json['content'];
    if ((text == null || text.isEmpty) && content is Map) {
      text = content['text'] as String?;
    }
    return AskResponse(
      chatId: json['chat_id'] as String?,
      text: text,
    );
  }
}
