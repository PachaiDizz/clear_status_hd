import 'package:url_launcher/url_launcher.dart';
import 'package:get_storage/get_storage.dart';

class WhatsAppVerifyService {
  static const String testNumber = '15556525144';
  static final _storage = GetStorage();
  static const _key = 'whatsapp_verified_at';

  static bool isVerified() {
    final verifiedAt = _storage.read(_key);
    if (verifiedAt == null) return false;

    final verifiedTime = DateTime.parse(verifiedAt);
    final now = DateTime.now();

    if (now.difference(verifiedTime).inHours >= 1) {
      _storage.remove(_key);
      return false;
    }

    return true;
  }

  static void markVerified() {
    _storage.write(_key, DateTime.now().toIso8601String());
  }

  static String getTimeRemaining() {
    final verifiedAt = _storage.read(_key);
    if (verifiedAt == null) return 'Not verified';

    final verifiedTime = DateTime.parse(verifiedAt);
    final remaining =
        const Duration(hours: 1) - DateTime.now().difference(verifiedTime);

    if (remaining.isNegative) return 'Expired';

    return '${remaining.inMinutes} min remaining';
  }

  static Future<void> openTestChat() async {
    final url = 'https://wa.me/$testNumber?text=Hello';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
