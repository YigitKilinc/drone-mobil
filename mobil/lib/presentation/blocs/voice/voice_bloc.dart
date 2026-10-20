import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drone_voice_control/domain/repositories/voice_repository.dart';
import 'package:drone_voice_control/domain/usecases/process_voice_command.dart';
import 'package:drone_voice_control/presentation/blocs/voice/voice_event.dart';
import 'package:drone_voice_control/presentation/blocs/voice/voice_state.dart';

/// Ses tanıma ve komut işleme BLoC'u
class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final VoiceRepository voiceRepository;
  final ProcessVoiceCommand processVoiceCommand;

  VoiceBloc({
    required this.voiceRepository,
    required this.processVoiceCommand,
  }) : super(const VoiceInitial()) {
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<VoiceResultReceived>(_onVoiceResultReceived);
    on<ResetVoice>(_onResetVoice);
  }

  /// Ses dinlemeyi başlat (Mikrofon açılır)
  Future<void> _onStartListening(
    StartListening event,
    Emitter<VoiceState> emit,
  ) async {
    emit(const VoiceListening());

    try {
      await voiceRepository.startListening(
        onResult: (voiceCommand) {
          add(VoiceResultReceived(
            text: voiceCommand.rawText,
            confidence: voiceCommand.confidence,
          ));
        },
        onError: (errorMessage) {
          emit(VoiceError(message: errorMessage));
        },
      );
    } catch (e) {
      emit(VoiceError(message: 'Mikrofon başlatılamadı: $e'));
    }
  }

  /// Ses dinlemeyi durdur
  Future<void> _onStopListening(
    StopListening event,
    Emitter<VoiceState> emit,
  ) async {
    try {
      await voiceRepository.stopListening();
    } catch (_) {}

    if (state is VoiceListening) {
      emit(const VoiceProcessing(rawText: 'İşleniyor...'));
    }
  }

  /// Ses tanıma sonucu alındığında
  Future<void> _onVoiceResultReceived(
    VoiceResultReceived event,
    Emitter<VoiceState> emit,
  ) async {
    emit(VoiceProcessing(rawText: event.text));

    try {
      final voiceCommand = await processVoiceCommand(
        rawText: event.text,
        confidence: event.confidence,
      );

      if (voiceCommand.isValid && voiceCommand.parsedCommand != null) {
        emit(VoiceCommandRecognized(
          command: voiceCommand.parsedCommand!,
          rawText: event.text,
          confidence: event.confidence,
        ));
      } else {
        emit(VoiceError(
          message: 'Anlaşılamayan komut: "${event.text}". (Örn: "ileri", "yüksel", "dur")',
        ));
      }
    } catch (e) {
      emit(VoiceError(message: 'Ses komutu işlenirken hata: ${e.toString()}'));
    }
  }

  /// Ses durumunu sıfırla
  Future<void> _onResetVoice(
    ResetVoice event,
    Emitter<VoiceState> emit,
  ) async {
    emit(const VoiceInitial());
  }
}
