import 'package:flutter/material.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/models/chat_models.dart';
import 'package:movil_architect/services/mobile_api_service.dart';

enum ChatState { loading, success, error, sending }

class ChatController extends ChangeNotifier {
  ChatController({
    required this.chatId,
    MobileApiService? mobileApiService,
  }) : _mobileApiService =
            mobileApiService ?? AppServices.instance.mobileApiService;

  final String chatId;
  final MobileApiService _mobileApiService;
  final TextEditingController messageController = TextEditingController();

  ChatState _state = ChatState.loading;
  String? _errorMessage;
  int? _errorStatusCode;
  ChatDetail? _detail;
  String? _pendingUserMessage;
  bool _disposed = false;

  ChatState get state => _state;
  String? get errorMessage => _errorMessage;
  int? get errorStatusCode => _errorStatusCode;
  ChatDetail? get detail => _detail;
  List<ChatMessage> get messages => _detail?.messages ?? [];
  String? get pendingUserMessage => _pendingUserMessage;
  String get title => _detail?.chat.title ?? 'Chat';
  bool get isSending => _state == ChatState.sending;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      _state = ChatState.loading;
      _errorMessage = null;
      _errorStatusCode = null;
      notifyListeners();
    }

    try {
      _detail = await _mobileApiService.getChat(chatId);
      if (_disposed) return;
      if (_state != ChatState.sending) {
        _state = ChatState.success;
        _errorMessage = null;
        _errorStatusCode = null;
      }
    } on ApiException catch (error) {
      if (_disposed) return;
      if (_state != ChatState.sending) {
        _state = ChatState.error;
        _errorStatusCode = error.statusCode;
        _errorMessage = error.statusCode == 404
            ? 'Conversación no encontrada.'
            : error.message;
      }
    } catch (_) {
      if (_disposed) return;
      if (_state != ChatState.sending) {
        _state = ChatState.error;
        _errorMessage = 'No se pudo cargar la conversación.';
        _errorStatusCode = null;
      }
    }

    if (!_disposed) notifyListeners();
  }

  Future<bool> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _state == ChatState.sending) return false;

    _pendingUserMessage = text;
    messageController.clear();
    _state = ChatState.sending;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();

    try {
      final analysisId = _detail?.lastAnalysisId;
      if (analysisId != null) {
        await _mobileApiService.sendFollowup(
          message: text,
          analysisId: analysisId,
          chatId: chatId,
        );
      } else {
        await _mobileApiService.sendAsk(
          message: text,
          chatId: chatId,
        );
      }
      if (_disposed) return false;
      await load(showLoading: false);
      if (_disposed) return false;
      _pendingUserMessage = null;
      _state = ChatState.success;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      if (_disposed) return false;
      _pendingUserMessage = null;
      _state = ChatState.success;
      _errorMessage = error.message;
      _errorStatusCode = error.statusCode;
      notifyListeners();
      return false;
    } catch (_) {
      if (_disposed) return false;
      _pendingUserMessage = null;
      _state = ChatState.success;
      _errorMessage = 'No se pudo enviar el mensaje.';
      _errorStatusCode = null;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    messageController.dispose();
    super.dispose();
  }
}
