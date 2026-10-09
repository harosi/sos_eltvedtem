import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

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

  double? _homeLat;
  double? _homeLng;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
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

    // 1. Mentés Flutter SharedPreferences-be
    await prefs.setString('target_name', name);
    await prefs.setString('target_phones', phones);
    await prefs.setString('my_sender_phone', myPhone);

    // 2. Mentés a HomeWidget megosztott tárhelyébe
    await HomeWidget.saveWidgetData<String>('target_name', name);
    await HomeWidget.saveWidgetData<String>('target_phones', phones);
    await HomeWidget.saveWidgetData<String>('my_sender_phone', myPhone);
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