import 'dart:ffi';

import 'package:ble_uart/screens/alarm_set_screen.dart';
import 'package:ble_uart/screens/catheter_count_screen.dart';
import 'package:ble_uart/screens/home_screen.dart';
import 'package:ble_uart/screens/settings_screen.dart';
import 'package:ble_uart/utils/ble_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int _currentIndex = 0;

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
