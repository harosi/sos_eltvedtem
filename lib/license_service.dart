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
      return true;
    }
    return false;
  }
}