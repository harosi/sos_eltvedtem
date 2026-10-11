<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';

class LicenseService {
  static const String _licenseKey = 'app_licensed_status';

  static Future<int> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedId = prefs.getInt('cached_device_id');
    if (savedId != null && savedId >= 1000 && savedId <= 9999) {
      return savedId;
    }
    final int newId = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
    await prefs.setInt('cached_device_id', newId);
    return newId;
  }

  static Future<bool> isLicensed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_licenseKey) ?? false;
  }

  static Future<bool> activate(String enteredCode) async {
    final devId = await getDeviceId();
    final expectedCode = ((devId * 73 + 12345) % 900000 + 100000).toString();

    if (enteredCode.trim() == expectedCode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_licenseKey, true);
=======
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseService {
  // Pontosan ugyanaz a salt és prime értékek, mint a Google Apps Scriptben
  static const int _secretSalt = 0x5F3759DF;
  static const int _prime1 = 73856093;
  static const int _prime2 = 19349663;

  /// 32 bites szorzás emulációja (mint a JS Math.imul)
  static int _imul(int a, int b) {
    return ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF;
  }

  /// 4 jegyű Készülékkód lekérése vagy sorsolása az adott telefonra
  static Future<int> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    int? devId = prefs.getInt('device_id');
    if (devId == null || devId < 1000 || devId > 9999) {
      devId = 1000 + Random().nextInt(9000);
      await prefs.setInt('device_id', devId);
    }
    return devId;
  }

  /// Feloldókód számítása a 4 jegyű devId-ból (100% egyezik a Google Scripttel)
  static int calculateActivationCode(int devId) {
    int hash = _imul((devId ^ _secretSalt), _prime1);
    hash = _imul((hash ^ (hash >> 13)), _prime2);
    hash = (hash ^ (hash >> 16)) & 0xFFFFFFFF;

    int finalCode = (hash.abs() % 900000) + 100000;
    return finalCode;
  }

  /// Licenc állapot ellenőrzése
  static Future<bool> isLicensed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_licensed') ?? false;
  }

  /// Beírt kód ellenőrzése
  static Future<bool> activate(String enteredCode) async {
    int devId = await getDeviceId();
    int expectedCode = calculateActivationCode(devId);
    int? entered = int.tryParse(enteredCode.trim());

    if (entered != null && entered == expectedCode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_licensed', true);
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
      return true;
    }
    return false;
  }
}