import 'package:get_storage/get_storage.dart';

class UsageService {
  static final _storage = GetStorage();
  static const _key = 'lifetime_message_count';
  static const int _maxFreeMessages = 3;

  /// Check if user can still send
  static bool canSend() {
    final used = _storage.read<int>(_key) ?? 0;
    return used < _maxFreeMessages;
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
  static int getMax() => _maxFreeMessages;

  /// Check if trial is permanently over
  static bool isTrialOver() {
    return !canSend();
  }
}
