import 'dart:math';

/// TipsService
///
/// Provides helpful tips shown to the user during compression.
/// Guarantees no two consecutive tips are the same.
class TipsService {
  // Single Random instance — not recreated on every call
  static final _random = Random();

  // Tracks last shown index to avoid immediate repeats
  static int _lastIndex = -1;

  static const List<String> _tips = [
    // Quality tips
    '💡 Always use the original video — never compress an already-compressed file.',
    '💡 Videos shot in 1080p or 4K give the best HD output after compression.',
    '💡 Avoid zooming in while recording — it reduces quality before compression even starts.',
    '💡 Well-lit videos compress much better than dark or grainy footage.',
    '💡 Fast motion scenes (sports, dancing) need higher bitrate — expect slightly larger files.',

    // Usage tips
    '💡 Do not close the app during compression — it will cancel the process.',
    '💡 Videos under 30 seconds are compressed at 1080p for maximum sharpness.',
    '💡 Videos between 30–60 seconds are compressed at 720p to stay within WhatsApp limits.',
    '💡 Videos longer than 60 seconds need to be trimmed before compressing.',
    '💡 Use the Split feature for long videos — each part will be 60 seconds max.',

    // WhatsApp tips
    '💡 Forward the received HD video to your WhatsApp Status — do not re-download it.',
    '💡 WhatsApp Status supports up to 60 seconds of video at full HD quality.',
    '💡 Landscape videos (16:9) fill the WhatsApp Status screen perfectly.',
    '💡 The verification expires every hour — re-verify if your upload fails.',
    '💡 Make sure WhatsApp notifications are on so you don\'t miss the HD delivery.',

    // Storage tips
    '💡 Compressed files are stored in a temp folder — they are cleared when you restart the app.',
    '💡 Save the HD video from WhatsApp before your Status expires in 24 hours.',
  ];

  /// Returns a random tip, guaranteed not to be the same as the last one shown.
  static String getRandomTip() {
    if (_tips.length == 1) return _tips[0];

    int index;
    do {
      index = _random.nextInt(_tips.length);
    } while (index == _lastIndex);

    _lastIndex = index;
    return _tips[index];
  }

  /// Returns a tip by index (safe — wraps around if out of bounds).
  static String getTip(int index) => _tips[index % _tips.length];

  /// Returns the total number of tips available.
  static int get count => _tips.length;
}
