import 'package:get_storage/get_storage.dart';
import 'whatsapp_verify_service.dart';

class UsageService {
  static final _storage = GetStorage();
  static const _key = 'lifetime_message_count';
  static const int maxLifetimeMessages = 3;
  static const String developerNumber = '601116266163';

  /// Check if user can still send (developer has unlimited)
  static bool canSend() {
    final phone = WhatsAppVerifyService.getPhoneNumber();
    if (phone == developerNumber) return true;

    final used = _storage.read<int>(_key) ?? 0;
    return used < maxLifetimeMessages;
  }

  /// Record a sent message (never resets)
  static void recordSend() {
    final used = (_storage.read<int>(_key) ?? 0) + 1;
    _storage.write(_key, used);
  }

  /// Get used count
  static int getUsed() {
    return _storage.read<int>(_key) ?? 0;
  }

  /// Get max free
  static int getMax() => maxLifetimeMessages;

  /// Get remaining count
  static int getRemaining() {
    final phone = WhatsAppVerifyService.getPhoneNumber();
    if (phone == developerNumber) return 999;

    return (maxLifetimeMessages - getUsed()).clamp(0, maxLifetimeMessages);
  }

  /// Check if limit is permanently over
  static bool isLimitOver() {
    return !canSend();
  }
}
