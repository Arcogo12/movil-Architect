import 'dart:io';

import 'package:flutter/material.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/models/analysis_models.dart';
import 'package:movil_architect/models/auth_models.dart';
import 'package:movil_architect/models/chat_models.dart';
import 'package:movil_architect/services/auth_service.dart';
import 'package:movil_architect/services/mobile_api_service.dart';

enum DashboardState { loading, success, error, empty }

class DashboardController extends ChangeNotifier {
  DashboardController({
    AuthService? authService,
    MobileApiService? mobileApiService,
  })  : _authService = authService ?? AppServices.instance.authService,
        _mobileApiService =
            mobileApiService ?? AppServices.instance.mobileApiService;

  final AuthService _authService;
  final MobileApiService _mobileApiService;
  final TextEditingController askController = TextEditingController();

  DashboardState _state = DashboardState.loading;
  String? _errorMessage;
  List<AnalysisSummary> _analyses = [];
  List<ChatSummary> _chats = [];
  bool _isSendingAsk = false;
  String? _askErrorMessage;
  String? _activeChatId;
  String? _pendingAskMessage;
  File? _pendingPlanoFile;
  String? _pendingPlanoName;
  bool _isLoadingPendingPlano = false;
  double _pendingPlanoLoadProgress = 0;
  bool _isAnalyzingPlano = false;
  File? _displayPlanoFile;
  String? _displayPlanoName;

  DashboardState get state => _state;
  String? get errorMessage => _errorMessage;
  List<AnalysisSummary> get analyses => _analyses;
  List<ChatSummary> get chats => _chats;
  UserModel? get user => _authService.currentUser;
  SubscriptionModel? get subscription => _authService.subscription;
  bool get isSendingAsk => _isSendingAsk;
  String? get askErrorMessage => _askErrorMessage;
  String? get activeChatId => _activeChatId;
  String? get pendingAskMessage => _pendingAskMessage;
  bool get hasActiveChat => _activeChatId != null;
  File? get pendingPlanoFile => _pendingPlanoFile;
  String? get pendingPlanoName => _pendingPlanoName;
  bool get hasPendingPlano => _pendingPlanoFile != null;
  bool get isLoadingPendingPlano => _isLoadingPendingPlano;
  double get pendingPlanoLoadProgress => _pendingPlanoLoadProgress;
  bool get isAnalyzingPlano => _isAnalyzingPlano;
  bool get hasPlanoAttachment =>
      _isLoadingPendingPlano ||
      _pendingPlanoFile != null ||
      _displayPlanoFile != null;
  File? get displayPlanoFile => _displayPlanoFile ?? _pendingPlanoFile;
  String? get displayPlanoName => _displayPlanoName ?? _pendingPlanoName;
  double? get displayPlanoLoadProgress =>
      _isLoadingPendingPlano ? _pendingPlanoLoadProgress : null;

  void _clearDisplayPlano() {
    _displayPlanoFile = null;
    _displayPlanoName = null;
  }

  Future<void> preparePendingPlano(File file, String name) async {
    _isLoadingPendingPlano = true;
    _pendingPlanoLoadProgress = 0;
    _pendingPlanoName = name;
    _pendingPlanoFile = null;
    _askErrorMessage = null;
    notifyListeners();

    try {
      if (!await file.exists()) {
        _askErrorMessage = 'No se pudo acceder al archivo.';
        _pendingPlanoName = null;
        return;
      }

      final total = await file.length();
      if (total == 0) {
        _askErrorMessage = 'El archivo está vacío.';
        _pendingPlanoName = null;
        return;
      }

      final raf = await file.open();
      try {
        const chunkSize = 64 * 1024;
        var read = 0;
        while (read < total) {
          final toRead =
              read + chunkSize > total ? total - read : chunkSize;
          await raf.read(toRead);
          read += toRead;
          _pendingPlanoLoadProgress = read / total;
          notifyListeners();
        }
      } finally {
        await raf.close();
      }

      _pendingPlanoFile = file;
      _pendingPlanoLoadProgress = 1;
    } catch (_) {
      _askErrorMessage = 'No se pudo cargar el plano.';
      _pendingPlanoName = null;
      _pendingPlanoFile = null;
    } finally {
      _isLoadingPendingPlano = false;
      notifyListeners();
    }
  }

  void clearPendingPlano() {
    if (_isLoadingPendingPlano || _isAnalyzingPlano) return;
    _pendingPlanoFile = null;
    _pendingPlanoName = null;
    _pendingPlanoLoadProgress = 0;
    _clearDisplayPlano();
    notifyListeners();
  }

  void cancelPendingPlanoLoad() {
    _isLoadingPendingPlano = false;
    _pendingPlanoFile = null;
    _pendingPlanoName = null;
    _pendingPlanoLoadProgress = 0;
    _clearDisplayPlano();
    notifyListeners();
  }

  /// Analiza el plano adjunto con el mensaje indicado.
  Future<AnalysisResult?> analyzePendingPlano({required String message}) async {
    if (_pendingPlanoFile == null ||
        _isAnalyzingPlano ||
        _isLoadingPendingPlano) {
      return null;
    }

    final text = message.trim();
    _pendingAskMessage = text.isEmpty ? 'Analiza este plano' : text;
    _isAnalyzingPlano = true;
    _askErrorMessage = null;

    final file = _pendingPlanoFile!;
    _displayPlanoFile = file;
    _displayPlanoName = _pendingPlanoName;
    _pendingPlanoFile = null;
    _pendingPlanoName = null;
    _pendingPlanoLoadProgress = 0;
    notifyListeners();

    try {
      final result = await _mobileApiService.analyze(
        file: file,
        message: text.isEmpty ? null : text,
        chatId: _activeChatId,
      );

      _pendingAskMessage = null;
      _clearDisplayPlano();

      if (result.chatId != null && result.chatId!.isNotEmpty) {
        _activeChatId = result.chatId;
      }

      await load(refresh: true);
      return result;
    } on ApiException catch (error) {
      _pendingAskMessage = null;
      _pendingPlanoFile = _displayPlanoFile;
      _pendingPlanoName = _displayPlanoName;
      _clearDisplayPlano();
      _askErrorMessage = error.message;
      return null;
    } catch (_) {
      _pendingAskMessage = null;
      _pendingPlanoFile = _displayPlanoFile;
      _pendingPlanoName = _displayPlanoName;
      _clearDisplayPlano();
      _askErrorMessage = 'No se pudo analizar el plano.';
      return null;
    } finally {
      _isAnalyzingPlano = false;
      notifyListeners();
    }
  }

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  void clearActiveChat() {
    _activeChatId = null;
    _pendingAskMessage = null;
    clearPendingPlano();
    notifyListeners();
  }

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      _state = DashboardState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final me = await _mobileApiService.me();
      _authService.updateSession(
        user: me.user,
        subscription: me.subscription,
      );

      _chats = await _mobileApiService.listChats();
      _analyses = await _mobileApiService.listAnalyses();
      _state = DashboardState.success;
      _errorMessage = null;
    } on ApiException catch (error) {
      _state = DashboardState.error;
      _errorMessage = error.message;
    } catch (_) {
      _state = DashboardState.error;
      _errorMessage = 'No se pudo cargar el dashboard.';
    }

    notifyListeners();
  }

  Future<void> logout() => _authService.logout();

  Future<void> deleteChat(String chatId) async {
    await _mobileApiService.deleteChat(chatId);
    _chats.removeWhere((chat) => chat.id == chatId);
    notifyListeners();
  }

  /// Envía una pregunta general (sin plano). Mantiene el chat activo en el dashboard.
  Future<String?> sendAsk() async {
    final text = askController.text.trim();
    if (text.isEmpty || _isSendingAsk) return null;

    _pendingAskMessage = text;
    askController.clear();
    _isSendingAsk = true;
    _askErrorMessage = null;
    notifyListeners();

    try {
      final response = await _mobileApiService.sendAsk(
        message: text,
        chatId: _activeChatId,
      );
      _activeChatId = response.chatId ??
          _activeChatId ??
          (_chats.isNotEmpty ? _chats.first.id : null);
      await load(refresh: true);
      _pendingAskMessage = null;
      _isSendingAsk = false;
      notifyListeners();
      return _activeChatId;
    } on ApiException catch (error) {
      _pendingAskMessage = null;
      _isSendingAsk = false;
      _askErrorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      _pendingAskMessage = null;
      _isSendingAsk = false;
      _askErrorMessage = 'No se pudo enviar la pregunta.';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    askController.dispose();
    super.dispose();
  }
}
