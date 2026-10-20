import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drone_voice_control/core/constants/app_constants.dart';
import 'package:drone_voice_control/core/theme/app_colors.dart';
import 'package:drone_voice_control/domain/entities/drone_command.dart';
import 'package:drone_voice_control/presentation/blocs/drone/drone_bloc.dart';
import 'package:drone_voice_control/presentation/blocs/drone/drone_event.dart';
import 'package:drone_voice_control/presentation/blocs/drone/drone_state.dart';
import 'package:drone_voice_control/presentation/blocs/voice/voice_bloc.dart';
import 'package:drone_voice_control/presentation/blocs/voice/voice_event.dart';
import 'package:drone_voice_control/presentation/blocs/voice/voice_state.dart';
import 'package:drone_voice_control/presentation/widgets/telemetry_display.dart';
import 'package:drone_voice_control/presentation/widgets/compass_widget.dart';
import 'package:drone_voice_control/presentation/widgets/voice_button.dart';
import 'package:drone_voice_control/presentation/widgets/command_history.dart';

class FlightScreen extends StatefulWidget {
  const FlightScreen({super.key});

  @override
  State<FlightScreen> createState() => _FlightScreenState();
}

class _FlightScreenState extends State<FlightScreen> {
  final List<String> _history = [];

  void _onVoiceCommandRecognized(VoiceCommandRecognized state) {
    setState(() {
      _history.insert(0, '${state.rawText} -> ${state.command.commandType.name}');
    });
    // Drone'a komutu gönder
    context.read<DroneBloc>().add(SendCommand(command: state.command));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesli Uçuş Kontrolü'),
        actions: [
          // Acil Durum / Hover Butonu
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<DroneBloc>().add(const EmergencyStop());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🛑 ACİL DURDURMA / HOVER ETKİNLEŞTİRİLDİ'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              icon: const Icon(Icons.emergency, color: Colors.white),
              label: const Text('DURDUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<VoiceBloc, VoiceState>(
            listener: (context, state) {
              if (state is VoiceCommandRecognized) {
                _onVoiceCommandRecognized(state);
              } else if (state is VoiceError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                );
              }
            },
          ),
        ],
        child: Column(
          children: [
            // Üst Kısım: Telemetri & Pusula
            BlocBuilder<DroneBloc, DroneState>(
              builder: (context, state) {
                if (state is DroneConnected) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.surface,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TelemetryDisplay(telemetry: state.telemetry),
                        ),
                        Expanded(
                          flex: 1,
                          child: CompassWidget(yaw: state.telemetry.yaw),
                        ),
                      ],
                    ),
                  );
                } else if (state is DroneCommandSent) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.surface,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TelemetryDisplay(telemetry: state.telemetry),
                        ),
                        Expanded(
                          flex: 1,
                          child: CompassWidget(yaw: state.telemetry.yaw),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: const Center(
                    child: Text(
                      'Drone Bağlantısı Bekleniyor...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),

            // Orta Kısım: Tanınan Komut ve Geçmiş
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Son algılanan ses metni
                    BlocBuilder<VoiceBloc, VoiceState>(
                      builder: (context, state) {
                        String statusText = 'Konuşmak için mikrofona basılı tutun';
                        Color statusColor = AppColors.textSecondary;

                        if (state is VoiceListening) {
                          statusText = 'Dinleniyor... Konuşun ("İleri git", "Yüksel", "Dur")';
                          statusColor = AppColors.accent;
                        } else if (state is VoiceProcessing) {
                          statusText = 'İşleniyor: "${state.rawText}"';
                          statusColor = AppColors.primary;
                        } else if (state is VoiceCommandRecognized) {
                          statusText = 'Komut uygulandı: "${state.rawText}"';
                          statusColor = AppColors.success;
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            statusText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Komut Geçmişi
                    const Text(
                      'Komut Günlüğü',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: CommandHistory(commands: _history),
                    ),
                  ],
                ),
              ),
            ),

            // Alt Kısım: Sesli Komut Butonu (Push to Talk)
            Container(
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: BlocBuilder<VoiceBloc, VoiceState>(
                builder: (context, state) {
                  VoiceButtonState btnState = VoiceButtonState.idle;
                  if (state is VoiceListening) {
                    btnState = VoiceButtonState.listening;
                  } else if (state is VoiceProcessing) {
                    btnState = VoiceButtonState.processing;
                  } else if (state is VoiceError) {
                    btnState = VoiceButtonState.error;
                  }

                  return VoiceButton(
                    buttonState: btnState,
                    onListenStart: () {
                      context.read<VoiceBloc>().add(const StartListening());
                    },
                    onListenStop: () {
                      context.read<VoiceBloc>().add(const StopListening());
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
