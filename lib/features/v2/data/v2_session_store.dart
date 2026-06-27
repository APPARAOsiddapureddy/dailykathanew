import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class V2SessionStore {
  const V2SessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'daily_katha_app_token';
  static const _phoneKey = 'daily_katha_phone_number';

  final FlutterSecureStorage _storage;

  Future<SavedAppSession?> read() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.trim().isEmpty) return null;
    final phoneNumber = await _storage.read(key: _phoneKey);
    return SavedAppSession(
      token: token.trim(),
      phoneNumber: phoneNumber?.trim() ?? '',
    );
  }

  Future<void> save({
    required String token,
    required String phoneNumber,
  }) async {
    await _storage.write(key: _tokenKey, value: token.trim());
    await _storage.write(key: _phoneKey, value: phoneNumber.trim());
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _phoneKey),
    ]);
  }
}

class SavedAppSession {
  const SavedAppSession({required this.token, required this.phoneNumber});

  final String token;
  final String phoneNumber;
}
