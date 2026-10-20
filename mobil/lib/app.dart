import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drone_voice_control/core/theme/app_theme.dart';
import 'package:drone_voice_control/core/constants/app_constants.dart';
import 'package:drone_voice_control/di/injection_container.dart';
import 'package:drone_voice_control/presentation/blocs/drone/drone_bloc.dart';
import 'package:drone_voice_control/presentation/blocs/voice/voice_bloc.dart';
import 'package:drone_voice_control/presentation/blocs/connection/connection_bloc.dart';
import 'package:drone_voice_control/presentation/screens/home_screen.dart';

/// Uygulama kök widget'ı.
/// MaterialApp yapılandırması, BLoC Provider'lar ve tema burada tanımlanır.
class DroneVoiceControlApp extends StatelessWidget {
  const DroneVoiceControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DroneBloc>(
          create: (_) => sl<DroneBloc>(),
        ),
        BlocProvider<VoiceBloc>(
          create: (_) => sl<VoiceBloc>(),
        ),
        BlocProvider<ConnectionBloc>(
          create: (_) => sl<ConnectionBloc>(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
