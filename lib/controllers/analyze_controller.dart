import 'dart:io';

import 'package:flutter/material.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/models/analysis_models.dart';
import 'package:movil_architect/services/mobile_api_service.dart';

enum AnalyzeState { idle, uploading, success, error }

class AnalyzeController extends ChangeNotifier {
  AnalyzeController({MobileApiService? mobileApiService})
      : _mobileApiService =
            mobileApiService ?? AppServices.instance.mobileApiService;

  final MobileApiService _mobileApiService;
  final TextEditingController messageController = TextEditingController();

  AnalyzeState _state = AnalyzeState.idle;
  String? _errorMessage;
  File? _selectedFile;
  String? _selectedFileName;
  AnalysisResult? _result;

  AnalyzeState get state => _state;
  String? get errorMessage => _errorMessage;
  File? get selectedFile => _selectedFile;
  String? get selectedFileName => _selectedFileName;
  AnalysisResult? get result => _result;

  void setFile(File file, String name) {
    _selectedFile = file;
    _selectedFileName = name;
    _errorMessage = null;
    notifyListeners();
  }

  void clearFile() {
    _selectedFile = null;
    _selectedFileName = null;
    notifyListeners();
  }

  Future<bool> analyze() async {
    if (_selectedFile == null) {
      _errorMessage = 'Selecciona un plano para analizar.';
      notifyListeners();
      return false;
    }

    _state = AnalyzeState.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _mobileApiService.analyze(
        file: _selectedFile!,
        message: messageController.text,
      );
      _state = AnalyzeState.success;
      return true;
    } on ApiException catch (error) {
      _state = AnalyzeState.error;
      _errorMessage = error.message;
      return false;
    } catch (error) {
      _state = AnalyzeState.error;
      _errorMessage = 'No se pudo procesar la respuesta del análisis.';
      assert(() {
        debugPrint('AnalyzeController error: $error');
        return true;
      }());
      return false;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _state = AnalyzeState.idle;
    _errorMessage = null;
    _result = null;
    notifyListeners();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
