import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'license_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SosApp());
}

class SosApp extends StatelessWidget {
  const SosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Eltévedtem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF111827),
      ),
      home: const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _targetNameController = TextEditingController();
  final TextEditingController _targetPhoneController = TextEditingController();
  final TextEditingController _myPhoneController = TextEditingController();
  final TextEditingController _licenseCodeController = TextEditingController();

  double? _homeLat;
  double? _homeLng;
  bool _isLoading = false;

  int _deviceId = 0;
  bool _isLicensed = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadLicenseInfo();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _loadLicenseInfo() async {
    final devId = await LicenseService.getDeviceId();
    final licensed = await LicenseService.isLicensed();
    setState(() {
      _deviceId = devId;
      _isLicensed = licensed;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetNameController.text = prefs.getString('target_name') ?? '';
      _targetPhoneController.text = prefs.getString('target_phones') ?? '';
      _myPhoneController.text = prefs.getString('my_sender_phone') ?? '';
      _homeLat = prefs.getDouble('home_lat');
      _homeLng = prefs.getDouble('home_lng');
    });
  }

  Future<void> _activateLicense() async {
    final code = _licenseCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérjük, adja meg a 6 jegyű feloldókódot!')),
      );
      return;
    }

    final success = await LicenseService.activate(code);
    if (success) {
      await HomeWidget.saveWidgetData<bool>('is_licensed', true);
      await HomeWidget.updateWidget(name: 'SosWidgetProvider');

      setState(() {
        _isLicensed = true;
      });
      _licenseCodeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Sikeres aktiválás! Az alkalmazás feloldva.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Érvénytelen aktivációs kód! Ellenőrizze a számokat.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveCurrentLocationAsHome() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('home_lat', pos.latitude);
      await prefs.setDouble('home_lng', pos.longitude);

      await HomeWidget.saveWidgetData<String>('home_lat', pos.latitude.toString());
      await HomeWidget.saveWidgetData<String>('home_lng', pos.longitude.toString());

      setState(() {
        _homeLat = pos.latitude;
        _homeLng = pos.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🏠 Jelenlegi pozíció otthonként elmentve!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba a pozíció lekérésekor: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final name = _targetNameController.text.trim();
    final phones = _targetPhoneController.text.trim();
    final myPhone = _myPhoneController.text.trim();

    await prefs.setString('target_name', name);
    await prefs.setString('target_phones', phones);
    await prefs.setString('my_sender_phone', myPhone);

    await HomeWidget.saveWidgetData<String>('target_name', name);
    await HomeWidget.saveWidgetData<String>('target_phones', phones);
    await HomeWidget.saveWidgetData<String>('my_sender_phone', myPhone);
    await HomeWidget.saveWidgetData<bool>('is_licensed', _isLicensed);
    await HomeWidget.updateWidget(name: 'SosWidgetProvider');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(name.isNotEmpty
              ? '✅ Beállítások mentve: $name ($phones)'
              : '✅ Telefonszám mentve: $phones'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Eltévedtem - Beállítások'),
        backgroundColor: const Color(0xFF1F2937),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: _isLicensed ? const Color(0xFF064E3B) : const Color(0xFF451A03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isLicensed ? Colors.greenAccent : Colors.orangeAccent,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isLicensed ? Icons.verified : Icons.lock_outline,
                        color: _isLicensed ? Colors.greenAccent : Colors.orangeAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLicensed ? 'LICENC AKTIVÁLVA' : 'LICENC AKTIVÁLÁSA SZÜKSÉGES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isLicensed ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Készülékkód: ${_deviceId == 0 ? "Betöltés..." : _deviceId}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ezt a 4 jegyű számot adja meg a weboldalon a végleges feloldókód megszerzéséhez.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (!_isLicensed) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _licenseCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '6 jegyű feloldókód',
                        hintText: 'pl. 123456',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFF1F2937),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _activateLicense,
                      icon: const Icon(Icons.key),
                      label: const Text('AKTIVÁLÁS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Text(
              'Értesítendő hozzátartozó adatai',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _targetNameController,
              decoration: const InputDecoration(
                labelText: 'Megnevezés / Név',
                hintText: 'pl. Fiam, Lányom, Gondozó',
                prefixIcon: Icon(Icons.person, color: Colors.amber),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _targetPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Értesítendő telefonszám',
                hintText: 'pl. +36701234567',
                prefixIcon: Icon(Icons.phone, color: Colors.greenAccent),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Saját adatok és Otthon pozíció',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _myPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Saját telefonszámom (opcionális)',
                hintText: 'Az SMS-be bekerülő segélykérő szám',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _saveCurrentLocationAsHome,
              icon: const Icon(Icons.my_location, color: Colors.orangeAccent),
              label: Text(
                _homeLat != null
                    ? 'Otthon rögzítve (${_homeLat!.toStringAsFixed(4)}, ${_homeLng!.toStringAsFixed(4)})'
                    : 'Jelenlegi hely beállítása Otthonként',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.orangeAccent),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _saveAllSettings,
              icon: const Icon(Icons.save, size: 24),
              label: const Text('BEÁLLÍTÁSOK MENTÉSE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}