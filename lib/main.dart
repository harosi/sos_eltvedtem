<<<<<<< HEAD
﻿import "dart:convert";
import "package:flutter/material.dart";
import "package:home_widget/home_widget.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:geolocator/geolocator.dart";
import "package:flutter_contacts/flutter_contacts.dart";
import "license_service.dart";
=======
﻿import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'license_service.dart';
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SOS Eltévedtem",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const SettingsBottomSheetScreen(),
    );
  }
}

class ContactPerson {
  String name;
  String phone;
  ContactPerson({required this.name, required this.phone});

  Map<String, String> toMap() => {"name": name, "phone": phone};
  factory ContactPerson.fromMap(Map<String, dynamic> map) => ContactPerson(
    name: map["name"] ?? "",
    phone: map["phone"] ?? "",
  );
}

class SettingsBottomSheetScreen extends StatefulWidget {
  const SettingsBottomSheetScreen({super.key});

  @override
  State<SettingsBottomSheetScreen> createState() => _SettingsBottomSheetScreenState();
}

class _SettingsBottomSheetScreenState extends State<SettingsBottomSheetScreen> {
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _myPhoneController = TextEditingController();
<<<<<<< HEAD
  final TextEditingController _newContactNameController = TextEditingController();
  final TextEditingController _newContactPhoneController = TextEditingController();
=======
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
  final TextEditingController _licenseCodeController = TextEditingController();

  double? _homeLat;
  double? _homeLng;
  List<ContactPerson> _contacts = [];

  int _deviceId = 0;
  bool _isLicensed = false;

  int _deviceId = 0;
  bool _isLicensed = false;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _loadAllData();
=======
    _loadSettings();
    _loadLicenseInfo();
    _checkLocationPermission();
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
  }

  Future<void> _loadAllData() async {
    final devId = await LicenseService.getDeviceId();
    final licensed = await LicenseService.isLicensed();

<<<<<<< HEAD
=======
  Future<void> _loadLicenseInfo() async {
    final devId = await LicenseService.getDeviceId();
    final licensed = await LicenseService.isLicensed();
    setState(() {
      _deviceId = devId;
      _isLicensed = licensed;
    });
  }

  Future<void> _loadSettings() async {
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
    final prefs = await SharedPreferences.getInstance();
    final savedSenderName = prefs.getString("sender_name") ?? "";
    final savedMyPhone = prefs.getString("my_sender_phone") ?? "06705577232";
    final savedLat = prefs.getDouble("home_lat");
    final savedLng = prefs.getDouble("home_lng");

    final contactsJson = prefs.getString("contacts_list_json");
    List<ContactPerson> loadedContacts = [];
    if (contactsJson != null && contactsJson.isNotEmpty) {
      try {
        final List decoded = jsonDecode(contactsJson);
        loadedContacts = decoded.map((e) => ContactPerson.fromMap(e)).toList();
      } catch (_) {}
    } else {
      final oldPhone = prefs.getString("target_phones") ?? "";
      final oldName = prefs.getString("target_name") ?? "";
      if (oldPhone.isNotEmpty) {
        loadedContacts.add(ContactPerson(name: oldName.isNotEmpty ? oldName : "Értesítendő", phone: oldPhone));
      }
    }

    setState(() {
      _deviceId = devId;
      _isLicensed = licensed;
      _senderNameController.text = savedSenderName;
      _myPhoneController.text = savedMyPhone;
      _homeLat = savedLat;
      _homeLng = savedLng;
      _contacts = loadedContacts;
    });
  }

  Future<void> _activateLicense() async {
    final code = _licenseCodeController.text.trim();
<<<<<<< HEAD
    if (code.isEmpty) return;

    final success = await LicenseService.activate(code);
    if (success) {
      await HomeWidget.saveWidgetData<bool>("is_licensed", true);
      await HomeWidget.updateWidget(name: "SosWidgetProvider");
      setState(() => _isLicensed = true);
      _licenseCodeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Sikeres aktiválás!"), backgroundColor: Colors.green),
        );
=======
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
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Hibás feloldókód!"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickFromContacts() async {
    try {
      final dynamic fc = FlutterContacts;
      final dynamic list = await fc.getAll();
      if (list != null && list is List && list.isNotEmpty && mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1E293B),
          builder: (ctx) => ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final dynamic c = list[i];
              String phone = "";
              try {
                if (c.phones != null && c.phones.isNotEmpty) {
                  phone = c.phones.first.number ?? "";
                }
              } catch (_) {}
              final String name = (c.displayName != null && c.displayName.toString().isNotEmpty)
                  ? c.displayName.toString()
                  : "Névtelen";
              return ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF10B981)),
                title: Text(name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(phone, style: const TextStyle(color: Colors.white60)),
                onTap: () {
                  setState(() {
                    _newContactNameController.text = name;
                    _newContactPhoneController.text = phone.replaceAll(" ", "");
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _saveCurrentLocationAsHome() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _homeLat = pos.latitude;
        _homeLng = pos.longitude;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble("home_lat", pos.latitude);
      await prefs.setDouble("home_lng", pos.longitude);
      await HomeWidget.saveWidgetData<String>("home_lat", pos.latitude.toString());
      await HomeWidget.saveWidgetData<String>("home_lng", pos.longitude.toString());
      await HomeWidget.updateWidget(name: "SosWidgetProvider");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🏠 Jelenlegi helyzet elmentve Otthonként!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hiba a pozíciónál: $e")));
      }
    }
  }

  void _addContact() {
    final name = _newContactNameController.text.trim();
    final phone = _newContactPhoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _contacts.add(ContactPerson(name: name.isNotEmpty ? name : "Névtelen", phone: phone));
      _newContactNameController.clear();
      _newContactPhoneController.clear();
    });
    _saveData();
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final senderName = _senderNameController.text.trim();
    final myPhone = _myPhoneController.text.trim();

<<<<<<< HEAD
    await prefs.setString("sender_name", senderName);
    await prefs.setString("my_sender_phone", myPhone);

    final contactsJson = jsonEncode(_contacts.map((c) => c.toMap()).toList());
    await prefs.setString("contacts_list_json", contactsJson);

    final allPhones = _contacts.map((c) => c.phone).join(",");
    final allNames = _contacts.map((c) => c.name).join(", ");

    await prefs.setString("target_phones", allPhones);
    await prefs.setString("target_name", allNames);

    await HomeWidget.saveWidgetData<String>("sender_name", senderName);
    await HomeWidget.saveWidgetData<String>("user_name", senderName);
    await HomeWidget.saveWidgetData<String>("my_sender_phone", myPhone);
    await HomeWidget.saveWidgetData<String>("target_phones", allPhones);
    await HomeWidget.saveWidgetData<String>("target_name", allNames);
    await HomeWidget.saveWidgetData<bool>("is_licensed", _isLicensed);
    await HomeWidget.updateWidget(name: "SosWidgetProvider");
=======
    await prefs.setString('target_name', name);
    await prefs.setString('target_phones', phones);
    await prefs.setString('my_sender_phone', myPhone);

    await HomeWidget.saveWidgetData<String>('target_name', name);
    await HomeWidget.saveWidgetData<String>('target_phones', phones);
    await HomeWidget.saveWidgetData<String>('my_sender_phone', myPhone);
    await HomeWidget.saveWidgetData<bool>('is_licensed', _isLicensed);
    await HomeWidget.updateWidget(name: 'SosWidgetProvider');
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Beállítások elmentve!"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS Eltévedtem"),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< HEAD
            // LICENC BLOKK
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
=======
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
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
<<<<<<< HEAD
                      Icon(_isLicensed ? Icons.verified : Icons.lock_outline,
                          color: _isLicensed ? Colors.greenAccent : Colors.orangeAccent, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _isLicensed ? "Licenc: Aktív" : "Licenc aktiválása szükséges",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
=======
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
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
                          color: _isLicensed ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
<<<<<<< HEAD
                  const SizedBox(height: 8),
                  Text(
                    "Készülékkód: $_deviceId",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (!_isLicensed) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _licenseCodeController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "6 jegyű feloldókód",
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _activateLicense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Aktiválás"),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // SEGÉLYKÉRŐ NEVE
            const Text("Segélykérő neve (SMS-ben szerepel):",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
=======
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
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
            TextField(
              controller: _senderNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "pl. Feri",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // SAJÁT TELEFONSZÁM
            const Text("Saját telefonszámod:",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _myPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "pl. 06705577232",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // OTTHON HELYZETE
            const Text("🏠 Otthon helyzete (a távolsághoz):",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _saveCurrentLocationAsHome,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.gps_fixed, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Icon(Icons.pin_drop, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text("Jelenlegi helyzet mentése Otthonként",
                        style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
<<<<<<< HEAD

            // ÚJ ÉRTESÍTENDŐ + TELEFONKÖNYV GOMB
            const Text("Új értesítendő személy:",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _newContactNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Név (pl. Vali)",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _newContactPhoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "+3630...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    tooltip: "Telefonkönyv megnyitása",
                    icon: const Icon(Icons.contacts, color: Colors.white),
                    onPressed: _pickFromContacts,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    tooltip: "Hozzáadás a listához",
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addContact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ÉRTESÍTENDŐK LISTÁJA
            const Text("Értesítendők listája:",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Nincs még mentett kapcsolat.", style: TextStyle(color: Colors.white38)),
              )
            else
              ..._contacts.asMap().entries.map((entry) {
                final idx = entry.key;
                final contact = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.name,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(contact.phone, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteContact(idx),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // MENTÉS GOMB
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveData,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Beállítások mentése",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
=======
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
>>>>>>> 2cbdb18ca336818f3e19ef77dbcf313ac6004050
              ),
            ),
          ],
        ),
      ),
    );
  }
}

