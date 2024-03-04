
import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/service/storage.dart';
import 'package:ble_uart/screens/alarm_set_screen.dart';
import 'package:ble_uart/screens/catheter_count_screen.dart';
import 'package:ble_uart/screens/home_screen.dart';
import 'package:ble_uart/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'alarm_alert_screen.dart';


GlobalKey bottomNavGKey = GlobalKey(debugLabel: 'bottomNavGKey');

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int _currentIndex = 0;
  late List<AlarmSettings> alarms = [];
  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Alarm.android) {
      checkAndroidNotificationPermission();
    }

    AlarmStorage.init();
    loadAlarms();

    print("[alarm_set_screen] load alarm done");

    subscription ??= Alarm.ringStream.stream.listen(
          (alarmSettings) => navigateToRingScreen(alarmSettings),
    );
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
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_currentIndex),
      ),
      bottomNavigationBar: SalomonBottomBar(
        key: bottomNavGKey,
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          SalomonBottomBarItem(icon: const Icon(Icons.home), title: const Text("Home"), selectedColor: Colors.blueGrey),
          SalomonBottomBarItem(icon: const Icon(Icons.check_box_outlined), title: const Text("Catheter"), selectedColor: Colors.pinkAccent),
          SalomonBottomBarItem(icon: const Icon(Icons.notifications_rounded), title: const Text("Alarm"), selectedColor: Colors.orange),
          SalomonBottomBarItem(icon: const Icon(Icons.settings), title: const Text("Settings"), selectedColor: Colors.deepPurpleAccent),
        ],
      ),
    );
  }
}
