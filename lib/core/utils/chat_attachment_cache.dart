import 'dart:convert';
import 'dart:io';

/// Guarda vistas previas de planos enviados en la sesión para mostrarlas
/// en burbujas de usuario cuando el API solo devuelve el nombre de archivo.
class ChatAttachmentCache {
  ChatAttachmentCache._();

  static final ChatAttachmentCache instance = ChatAttachmentCache._();

  final Map<String, String> _byFilename = {};

  Future<void> putFile(String filename, File file) async {
    final name = filename.trim();
    if (name.isEmpty) return;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      _byFilename[name.toLowerCase()] = base64Encode(bytes);
    } catch (_) {
      // Si no se puede leer el archivo, la burbuja seguirá con el nombre.
    }
  }

  void putBase64(String filename, String base64) {
    final name = filename.trim();
    final value = base64.trim();
    if (name.isEmpty || value.isEmpty) return;
    _byFilename[name.toLowerCase()] = value;
  }

  String? get(String? filename) {
    if (filename == null || filename.trim().isEmpty) return null;
    return _byFilename[filename.trim().toLowerCase()];
  }
}
