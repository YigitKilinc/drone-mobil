import 'package:equatable/equatable.dart';

/// Ses tanıma BLoC'u için event sınıfları
abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object?> get props => [];
}

/// Ses dinlemeyi başlat
class StartListening extends VoiceEvent {
  const StartListening();
}

/// Ses dinlemeyi durdur
class StopListening extends VoiceEvent {
  const StopListening();
}

/// Ses tanıma sonucu alındı
class VoiceResultReceived extends VoiceEvent {
  final String text;
  final double confidence;

  const VoiceResultReceived({
    required this.text,
    required this.confidence,
  });

  @override
  List<Object?> get props => [text, confidence];
}

/// Ses durumunu sıfırla
class ResetVoice extends VoiceEvent {
  const ResetVoice();
}
