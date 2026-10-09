import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String accessTokenKey = 'token';
  static const String refreshTokenKey = 'refresh_token';
  static const String accessUserKey = 'user';
  static const String refreshUserKey = 'refresh_user';
  static const String userQRKey = 'user_qr';

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: accessTokenKey, value: accessToken);

    if (refreshToken != null) {
      await _storage.write(key: refreshTokenKey, value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }

  static Future<void> logout() async {
    await _storage.delete(key: accessTokenKey);

    await _storage.delete(key: refreshTokenKey);
  }

  static Future<void> saveUser({
    required String accessUser,
    String? refreshUser,
  }) async {
    await _storage.write(key: accessUserKey, value: accessUser);

    if (refreshUser != null) {
      await _storage.write(key: refreshTokenKey, value: refreshUser);
    }
  }

  static Future<String?> getAccessUser() async {
    return await _storage.read(key: accessUserKey);
  }

  static Future<String?> getRefreshUser() async {
    return await _storage.read(key: refreshUserKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> saveQR({
    required String qrCode,
    String? refreshQRcode,
  }) async {
    await _storage.write(key: userQRKey, value: qrCode);

    if (refreshQRcode != null) {
      await _storage.write(key: refreshUserKey, value: refreshQRcode);
    }
  }

  static Future<String?> getQR() async {
    try {
      return await _storage.read(key: userQRKey);
    } catch (e) {
      return null;
    }
  }
}
