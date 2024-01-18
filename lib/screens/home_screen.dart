import 'package:ble_uart/screens/uart_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.device, required this.service});

  final BluetoothDevice device;
  final BluetoothService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  static const String rx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write data to the rx characteristic to send it to the UART interface.
  static const String tx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Enable notifications for the tx characteristic to receive data from the application.

  List<BluetoothCharacteristic> get characteristic => widget.service.characteristics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME'),
        centerTitle: true,
      ),

      body: Center(
        child: Column(
          children: [
            const Text("WELCOME HOME"),
            OutlinedButton(
              onPressed: (){
                Navigator.pushNamed(
                  context,
                  UARTScreen.routeName,
                  arguments: ScreenArguments(
                    widget.service,
                    widget.device.platformName.toString(),
                  ),
                );
              },
              child: const Text('UART Communication'),
            ),
          ],
        ),
      ),
    );
  }
}
