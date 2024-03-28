
import 'dart:async';
import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';

import 'package:ble_uart/screens/alarm_set_screen.dart';
import 'package:ble_uart/screens/catheter_count_screen.dart';
import 'package:ble_uart/screens/home_screen.dart';
import 'package:ble_uart/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/back_ground_service.dart';
import 'alarm_alert_screen.dart';


GlobalKey bottomNavGKey = GlobalKey(debugLabel: 'bottomNavGKey');
late String userName;

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int _currentIndex = 0;
  late List<AlarmSettings> alarms = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Alarm.android) {
      checkAndroidNotificationPermission();
    }

    loadAlarms();

    print("[alarm_set_screen] load alarm done");
  }

  Future<void> sendEmail() async {
    String? guardian;

    SharedPreferences pref = await SharedPreferences.getInstance();
    userName = pref.getString("name") ?? "No name";
    guardian = pref.getString("guardianEmail");

    if(guardian == "") guardian = "medilightalert@gmail.com";

    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost',
      },
      body: json.encode({
        'service_id': 'service_3gzs5mj',
        'template_id': 'template_h9e6z72',
        'user_id': 'DpL6M9GiRBZFBI1bh',
        'accessToken': '1-6LZXIKob51cgNkHjbmt',
        'template_params': {
          'user_name': userName,
          'send_to': guardian,
        },
      }),
    );

    print(response.body);
  }

  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      alarmPrint('Requesting notification permission...');
      final res = await Permission.notification.request();
      alarmPrint(
        'Notification permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }

  void loadAlarms() {
    setState(() {
      print("[alarm_set_screen] load alarms start");
      try{
        alarms = Alarm.getAlarms();
        alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
      }catch(e){
        print("[alarm_set_screen] no saved alarms");
      }
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AlarmAlertScreen(alarmSettings: alarmSettings),
        ));
    loadAlarms();
  }

  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const CatheterCountScreen(),
    const AlarmSetScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    Background.startFlutterBackgroundService(() async{
      Background.connectToDevice();
      Background.alarmSendEmail();
    });
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_currentIndex),
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        child: SalomonBottomBar(
          key: bottomNavGKey,
          backgroundColor: Colors.white,
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            SalomonBottomBarItem(icon: const Icon(Icons.home, size: 40,), title: const Text("Home", style: TextStyle(fontSize: 15),), selectedColor: Colors.blueGrey),
            SalomonBottomBarItem(icon: const Icon(Icons.check_box_outlined, size: 40,), title: const Text("Catheter", style: TextStyle(fontSize: 15),), selectedColor: Colors.pinkAccent),
            SalomonBottomBarItem(icon: const Icon(Icons.notifications_rounded, size: 40,), title: const Text("Alarm", style: TextStyle(fontSize: 15),), selectedColor: Colors.orange),
            SalomonBottomBarItem(icon: const Icon(Icons.settings, size: 40,), title: const Text("Settings", style: TextStyle(fontSize: 15),), selectedColor: Colors.deepPurpleAccent),
          ],
        ),
      ),

    );
  }
}
