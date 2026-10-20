/// SpeechService - Ses tanıma servisi.
///
/// `speech_to_text` paketini sarmalayarak Türkçe (tr_TR) ses
/// tanıma desteği sağlar. Tanınan metni güvenilirlik skoru ile
/// birlikte stream olarak yayınlar.
library;

import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Ses tanıma sonucunu temsil eden veri sınıfı.
class SpeechResult {
  /// Tanınan metin
  final String text;

  /// Güvenilirlik skoru (0.0 – 1.0)
  final double confidence;

  /// Tanıma işleminin tamamlanıp tamamlanmadığı
  final bool isFinal;

  const SpeechResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
  });
}

/// Ses tanıma servisi.
///
/// `speech_to_text` paketini kullanarak cihazın mikrofonundan
/// ses dinler ve metne çevirir. Türkçe dil desteği sağlar.
class SpeechService {
  /// speech_to_text paketi instance'ı
  final SpeechToText _speech = SpeechToText();

  /// Tanıma sonuçlarını yayınlayan stream controller
  final _resultController = StreamController<SpeechResult>.broadcast();

  /// Servisin başlatılıp başlatılmadığı
  bool _isInitialized = false;

  /// Dinlemenin aktif olup olmadığı
  bool _isListening = false;

  /// Tanıma sonuçlarının akışı
  Stream<SpeechResult> get resultStream => _resultController.stream;

  /// Dinlemenin aktif olup olmadığı
  bool get isListening => _isListening;

  /// Ses tanıma servisini başlatır.
  ///
  /// Mikrofon izni ister ve ses tanıma motorunu hazırlar.
  /// Başarılıysa `true` döndürür.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: false,
      );

      if (_isInitialized) {
        _log('Ses tanıma servisi başlatıldı');
      } else {
        _log('Ses tanıma servisi başlatılamadı');
      }

      return _isInitialized;
    } catch (e) {
      _log('Başlatma hatası: $e');
      return false;
    }
  }

  /// Ses dinlemeyi başlatır.
  ///
  /// [locale] parametresi dil kodunu belirtir (varsayılan: "tr_TR").
  /// [listenFor] parametresi maksimum dinleme süresini belirtir.
  /// [pauseFor] parametresi sessizlik sonrası durma süresini belirtir.
  Future<bool> startListening({
    String locale = 'tr_TR',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return false;
    }

    if (_isListening) {
      _log('Zaten dinleniyor');
      return true;
    }

    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: locale,
        listenFor: listenFor,
        pauseFor: pauseFor,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      );

      _isListening = true;
      _log('Dinleme başladı (dil: $locale)');
      return true;
    } catch (e) {
      _log('Dinleme başlatma hatası: $e');
      return false;
    }
  }

  /// Ses dinlemeyi durdurur.
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      _log('Dinleme durduruldu');
    } catch (e) {
      _log('Dinleme durdurma hatası: $e');
    }
  }

  /// Ses tanıma servisinin kullanılabilir olup olmadığını kontrol eder.
  Future<bool> get isAvailable async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  /// Desteklenen dillerin listesini döndürür.
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    final locales = await _speech.locales();
    return locales.map((l) => l.localeId).toList();
  }

  // ── Dahili Callback'ler ──

  /// Ses tanıma sonucu geldiğinde çağrılır.
  void _onResult(SpeechRecognitionResult result) {
    final speechResult = SpeechResult(
      text: result.recognizedWords,
      confidence: result.hasConfidenceRating ? result.confidence : 0.85,
      isFinal: result.finalResult,
    );

    if (!_resultController.isClosed) {
      _resultController.add(speechResult);
    }

    _log('Tanıma: "${result.recognizedWords}" '
        '(güven: ${speechResult.confidence}, '
        'final: ${result.finalResult})');
  }

  /// Ses tanıma durum değişikliğinde çağrılır.
  void _onStatus(String status) {
    _log('Durum: $status');

    // "done" veya "notListening" durumunda dinleme bayrağını güncelle
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  /// Ses tanıma hatası oluştuğunda çağrılır.
  void _onError(dynamic error) {
    _log('Hata: $error');
    _isListening = false;
  }

  /// Debug log mesajı yazdırır.
  void _log(String message) {
    // ignore: avoid_print
    print('[SpeechService] $message');
  }

  /// Servisi kapatır ve kaynakları serbest bırakır.
  Future<void> dispose() async {
    await stopListening();
    await _resultController.close();
    _speech.cancel();
  }
}
