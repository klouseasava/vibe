import 'package:vibration/vibration.dart';

class VibeHaptics {
  // Pattern for loud speech (short pulses)
  static void pulseSpeech() {
    Vibration.vibrate(duration: 100, amplitude: 128);
  }

  // Pattern for music/rhythm (thumping)
  static void pulseMusic() {
    Vibration.vibrate(
      pattern: [0, 200, 100, 200], // Thump...thump
      intensities: [0, 255, 0, 255],
    );
  }

  static void alertHighVolume() {
    Vibration.vibrate(duration: 500); // Constant buzz for loud alerts
  }
}
