import 'dart:io';

import 'package:dio/dio.dart';
import 'package:movil_architect/core/network/api_client.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/models/analysis_models.dart';
import 'package:movil_architect/models/auth_models.dart';
import 'package:movil_architect/models/chat_models.dart';

class MobileApiService {
  MobileApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<HealthResponse> health() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/mobile/health',
      );
      return HealthResponse.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<MeResponse> me() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/mobile/me',
      );
      final data = response.data ?? {};
      if (data['ok'] == false) {
        throw ApiException(
          message: data['message'] as String? ??
              'No se pudo obtener el perfil del usuario.',
        );
      }
      return MeResponse.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<AnalysisSummary>> listAnalyses({int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        '/api/analyses',
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(AnalysisSummary.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ChatSummary>> listChats() async {
    try {
      final response = await _apiClient.dio.get<dynamic>('/api/chats');
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ChatSummary.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChatDetail> getChat(String chatId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/chats/$chatId',
      );
      return ChatDetail.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> sendFollowup({
    required String message,
    required int analysisId,
    String? chatId,
  }) async {
    try {
      await _apiClient.dio.post<void>(
        '/api/analyze/followup',
        data: FormData.fromMap({
          'message': message.trim(),
          'analysis_id': analysisId.toString(),
          if (chatId != null && chatId.isNotEmpty) 'chat_id': chatId,
        }),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AskResponse> sendAsk({
    required String message,
    String? chatId,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/ask',
        data: FormData.fromMap({
          'message': message.trim(),
          if (chatId != null && chatId.isNotEmpty) 'chat_id': chatId,
        }),
      );
      return AskResponse.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _apiClient.dio.delete<void>('/api/chats/$chatId');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AnalysisResult> analyze({
    required File file,
    String? message,
    String? chatId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
        'auto_calibrate': '1',
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        if (chatId != null && chatId.isNotEmpty) 'chat_id': chatId,
      });

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/mobile/analyze',
        data: formData,
      );

      return AnalysisResult.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
