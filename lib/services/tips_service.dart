import 'dart:math';

class TipsService {
  static final List<String> _tips = [
    '💡 For best HD results, use original videos that are already high quality.',
    '💡 Avoid compressing videos that are already low resolution.',
    '💡 Do not close the app during compression.',
    '💡 Videos with lots of motion need higher bitrate for best quality.',
    '💡 Forward the received message to Status for HD quality.',
    '💡 Dark scenes compress better than bright, fast-moving scenes.',
    '💡 Keep your original video under 2 minutes for best compression results.',
    '💡 The verification expires every hour — re-verify if upload fails.',
    '💡 You can share up to 1,000 HD videos per month for free.',
    '💡 Use landscape mode when recording for best WhatsApp Status fit.',
  ];

  static String getRandomTip() {
    final random = Random();
    return _tips[random.nextInt(_tips.length)];
  }

  static String getTip(int index) {
    return _tips[index % _tips.length];
  }
}
