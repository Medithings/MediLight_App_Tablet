import 'dart:ffi';

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
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_currentIndex),
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          SalomonBottomBarItem(icon: const Icon(Icons.home), title: const Text("Home"), selectedColor: Colors.blueGrey),
          SalomonBottomBarItem(icon: const Icon(Icons.settings), title: const Text("Settings"), selectedColor: Colors.deepPurpleAccent),
        ],
      ),
    );
  }
}
