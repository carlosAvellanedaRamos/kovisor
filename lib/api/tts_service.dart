import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _tts.setLanguage('es-ES'); // Español
      await _tts.setSpeechRate(0.5); // Velocidad más lenta para mejor comprensión
      await _tts.setVolume(1.0); // Volumen al máximo
      await _tts.setPitch(1.0); // Tono normal
      _isInitialized = true;
    }
  }

  static Future<void> speak(String text) async {
    await _ensureInitialized();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }
}