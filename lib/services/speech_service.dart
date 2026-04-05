import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps the speech_to_text plugin for voice-based product search.
///
/// Usage:
/// ```dart
/// final speech = SpeechService();
/// final available = await speech.initialize();
/// if (available) {
///   speech.startListening(onResult: (text) => searchProducts(text));
/// }
/// ```
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  /// Initializes the speech recognizer. Returns `true` if speech recognition
  /// is available on the device.
  Future<bool> initialize() async {
    _isInitialized = await _speech.initialize(
      onError: (error) {
        _isListening = false;
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        }
      },
    );
    return _isInitialized;
  }

  /// Starts listening for speech input.
  ///
  /// [onResult] is called with the recognized text (partial and final).
  /// [localeId] defaults to `'en_IN'` for Indian English; set to `'hi_IN'`
  /// for Hindi input.
  void startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'en_IN',
  }) {
    if (!_isInitialized) return;
    _isListening = true;
    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: localeId,
      listenMode: stt.ListenMode.search,
      cancelOnError: true,
    );
  }

  /// Stops the current listening session.
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  /// Cancels the current listening session without returning results.
  Future<void> cancel() async {
    _isListening = false;
    await _speech.cancel();
  }

  /// Returns available locales for speech recognition.
  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) return [];
    return _speech.locales();
  }
}
