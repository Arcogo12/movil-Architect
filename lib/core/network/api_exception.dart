import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.isOffline = false,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final bool isOffline;

  bool get isPlanLimit => statusCode == 402;

  factory ApiException.fromDio(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Sin conexión al servidor. Revisa tu red o la URL configurada.',
        isOffline: true,
      );
    }

    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;
    final path = error.requestOptions.path;

    String message = 'Ocurrió un error inesperado.';
    String? code;
    if (data is String) {
      message = data.isNotEmpty ? data : message;
    } else if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is Map) {
        code = detail['code']?.toString();
        final nested = detail['message']?.toString();
        if (nested != null && nested.isNotEmpty) message = nested;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          message = first['msg'] as String;
        } else {
          message = first.toString();
        }
      }
    } else if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }

    switch (statusCode) {
      case 401:
        if (message == 'Ocurrió un error inesperado.') {
          final isAuthAttempt =
              path.contains('/login') || path.contains('/register');
          message = isAuthAttempt
              ? 'Correo o contraseña incorrectos'
              : 'Sesión expirada. Inicia sesión de nuevo.';
        }
      case 403:
        message = message == 'Ocurrió un error inesperado.' ||
                message == 'Forbidden'
            ? 'No tienes permiso para esta acción.'
            : message;
      case 402:
        if (message == 'Ocurrió un error inesperado.') {
          message = code == 'trial_exhausted'
              ? 'Tu prueba se agotó. Crea una cuenta o inicia sesión.'
              : 'Has alcanzado el límite de tu plan.';
        }
      case 413:
        message = 'El archivo es demasiado grande.';
      case 400:
        message = message == 'Ocurrió un error inesperado.'
            ? 'Formato no soportado o archivo inválido.'
            : message;
      case 404:
        message = message == 'Ocurrió un error inesperado.' ||
                message == 'Not Found'
            ? 'Ruta no encontrada en el servidor. Verifica la URL en Ajustes.'
            : message;
      case 500:
      case 502:
      case 503:
        if (message == 'Ocurrió un error inesperado.' ||
            message == 'Internal Server Error') {
          message = statusCode == 503
              ? 'El servidor no está configurado correctamente.'
              : 'Error en el servidor al procesar la solicitud.';
        }
    }

    return ApiException(message: message, statusCode: statusCode, code: code);
  }

  @override
  String toString() => message;
}
