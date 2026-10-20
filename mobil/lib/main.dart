import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'di/injection_container.dart';
import 'core/utils/logger.dart';

/// Uygulama giriş noktası.
/// Bağımlılık enjeksiyonunu başlatır ve uygulamayı çalıştırır.
void main() async {
  // Flutter engine'in hazır olduğundan emin ol
  WidgetsFlutterBinding.ensureInitialized();

  // Ekran yönünü dikey olarak kilitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Sistem UI stilini ayarla (koyu tema için)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  AppLogger.info('Uygulama başlatılıyor...');

  // Bağımlılık enjeksiyonunu başlat
  try {
    await initializeDependencies();
    AppLogger.info('Bağımlılıklar başarıyla yüklendi ✓');
  } catch (e, stackTrace) {
    AppLogger.error(
      'Bağımlılık yükleme hatası',
      error: e,
      stackTrace: stackTrace,
    );
  }

  AppLogger.info('Drone Sesli Kontrol uygulaması hazır 🚁');

  // Uygulamayı çalıştır
  runApp(const DroneVoiceControlApp());
}
