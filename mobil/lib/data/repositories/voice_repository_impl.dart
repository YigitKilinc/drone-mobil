import 'dart:async';
import 'package:drone_voice_control/core/constants/drone_commands.dart';
import 'package:drone_voice_control/data/datasources/speech_service.dart';
import 'package:drone_voice_control/domain/entities/voice_command.dart';
import 'package:drone_voice_control/domain/repositories/voice_repository.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  final SpeechService speechService;
  final _commandStreamController = StreamController<VoiceCommand>.broadcast();

  VoiceRepositoryImpl({required this.speechService});

  @override
  Future<bool> initialize() async {
    return await speechService.initialize();
  }

  @override
  Future<void> startListening({
    required Function(VoiceCommand) onResult,
    required Function(String) onError,
  }) async {
    await speechService.startListening(
      onResult: (text, confidence) {
        final parsed = DroneCommandMap.parseVoiceCommand(text);
        final voiceCommand = VoiceCommand(
          rawText: text,
          confidence: confidence,
          parsedCommand: parsed,
          timestamp: DateTime.now(),
          isValid: parsed != null,
        );
        _commandStreamController.add(voiceCommand);
        onResult(voiceCommand);
      },
      onError: onError,
    );
  }

  @override
  Future<void> stopListening() async {
    await speechService.stopListening();
  }

  @override
  Stream<VoiceCommand> get voiceStream => _commandStreamController.stream;

  @override
  bool get isListening => speechService.isListening;
}

