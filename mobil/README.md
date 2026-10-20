# 🚁 DroneVoice — Sesli Komutla Drone Kontrol Mobil Uygulaması

Bu mobil uygulama, **sim-drone** (Gazebo Sim Harmonic & ROS 2 Jazzy) projesine %100 uyumlu, sesli komutlarla quadcopter kontrolü sağlayan **Flutter tabanlı cross-platform** bir mobil uygulamadır.

---

## 📌 Proje Genel Bakışı & Mimari Uyumluluk

`sim-drone` projesindeki hız, koordinat ve mesaj formatlarıyla tam eşleşir:
- **Komut Topic'i**: `/drone/cmd_vel` (`geometry_msgs/msg/Twist`)
- **Odometri**: `/drone/odometry` (`nav_msgs/msg/Odometry`)
- **IMU**: `/drone/imu` (`sensor_msgs/msg/Imu`)
- **Hız Adımları**: Lineer `±0.5 m/s`, Açısal `±0.5 rad/s` (Gazebo motor sınırlarına tam uyumlu)
- **Güvenlik Limitleri**: Max XY: `3.0 m/s`, Max Z: `2.5 m/s`, Max Yaw: `2.0 rad/s`

---

## 🏗️ Katmanlı Mimari (Clean Architecture + BLoC)

```text
mobil/
├── android/                         # Android izinleri (Mikrofon, İnternet)
├── ios/                             # iOS izinleri (NSMicrophone, NSLocalNetwork)
├── pubspec.yaml                     # Flutter bağımlılıkları
├── start_bridge.sh                  # Simülasyon köprüsünü başlatan tek tık script
├── scripts/
│   └── mobile_ws_bridge.py          # Hafif dahili WebSocket köprüsü
├── lib/
│   ├── main.dart                    # Uygulama başlangıcı ve DI başlatma
│   ├── app.dart                     # MaterialApp & Tema & BLoC Provider'lar
│   ├── di/
│   │   └── injection_container.dart # GetIt Servis Bulucu
│   ├── core/                        # Çekirdek sabitler, renkler, temalar
│   │   ├── constants/               # Topic adları, komut eşleştirmeleri
│   │   ├── enums/                   # Uçuş durumları, komut tipleri
│   │   ├── theme/                   # Koyu tema & renk paleti
│   │   └── utils/                   # İzin yöneticisi ve loglama
│   ├── domain/                      # İş Mantığı (Saf Dart)
│   │   ├── entities/                # DroneCommand, Telemetry, VoiceCommand
│   │   ├── repositories/            # Arayüzler (Drone, Voice, Settings)
│   │   └── usecases/                # ProcessVoiceCommand, SendDroneCommand
│   ├── data/                        # Veri Katmanı
│   │   ├── datasources/             # rosbridge_service, speech_service, tts
│   │   ├── models/                  # Twist JSON serializer
│   │   └── repositories/            # Repository implementasyonları
│   └── presentation/                # UI ve State Yönetimi
│       ├── blocs/                   # DroneBloc, VoiceBloc, ConnectionBloc
│       ├── screens/                 # HomeScreen, FlightScreen, SettingsScreen, LogScreen
│       └── widgets/                 # VoiceButton, TelemetryDisplay, CompassWidget vb.
```

---

## 🎤 Desteklenen Türkçe Sesli Komutlar

Mikrofon butonuna basılı tutarak konuşabilirsiniz:

| Sesli Komut | Eylem | Twist Mesajı Karşılığı |
| :--- | :--- | :--- |
| **"Kalkış"** / **"Yüksel"** / **"Yukarı"** | İrtifa kazanır | `linear.z: +0.5 m/s` |
| **"Alçal"** / **"İniş"** / **"Aşağı"** | İrtifa kaybeder / İner | `linear.z: -0.5 m/s` |
| **"İleri"** / **"İleri git"** | İleri doğru hızlanır | `linear.x: +0.5 m/s` |
| **"Geri"** / **"Geri gel"** | Geriye doğru hareket eder | `linear.x: -0.5 m/s` |
| **"Sol"** / **"Sola git"** | Sola yanal kayma | `linear.y: +0.5 m/s` |
| **"Sağ"** / **"Sağa git"** | Sağa yanal kayma | `linear.y: -0.5 m/s` |
| **"Sola dön"** | Kendi etrafında sola döner | `angular.z: +0.5 rad/s` |
| **"Sağa dön"** | Kendi etrafında sağa döner | `angular.z: -0.5 rad/s` |
| **"Dur"** / **"Bekle"** / **"Stop"** | **Havada Asılı Kal (Hover)** | `linear: {0,0,0}, angular: {0,0,0}` |

> 🚨 **Acil Durdurma:** Ekrandaki kırmızı **"DURDUR"** butonuna basıldığında tüm hızlar anında sıfırlanır ve drone havada asılı kalır (`Hover`).

---

## 🚀 Nasıl Çalıştırılır? (Adım Adım)

### Adım 1: Simülasyonu Başlatın
Terminal 1:
```bash
cd ~/Desktop/mobil/sim-drone
./run_sim.sh
```

### Adım 2: WebSocket Köprüsünü Başlatın
Terminal 2:
```bash
cd ~/Desktop/mobil
./start_bridge.sh
```
*Ekranda telefonunuzdan girmeniz gereken yerel IP adresi yazacaktır (Örn: `ws://192.168.1.xxx:9090`).*

### Adım 3: Mobil Uygulamayı Başlatın
Telefonunuz ile bilgisayarınızın **aynı Wi-Fi ağına** bağlı olduğundan emin olun.
Terminal 3:
```bash
cd ~/Desktop/mobil
flutter pub get
flutter run
```
1. Uygulama açıldığında ekrandaki IP kutusuna bilgisayarınızın IP adresini girin ve **"Drone'a Bağlan"** butonuna basın.
2. **"SESLİ UÇUŞ KONTROL PANELİ"** butonuna tıklayın.
3. Mikrofon butonuna basılı tutarak konuşun (örn: *"Kalkış"*, *"İleri git"*, *"Dur"*). Drone simülasyonda hareket edecektir!

