import 'dart:async';
import 'dart:convert';

import 'package:ble_uart/screens/uart_screen.dart';
import 'package:ble_uart/utils/ble_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key,});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  static const String rx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write data to the rx characteristic to send it to the UART interface.
  static const String tx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Enable notifications for the tx characteristic to receive data from the application.

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<List<int>> _lastValueSubscription;

  late BluetoothDevice device;
  late BluetoothService service;
  late List<BluetoothCharacteristic> characteristic;

  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  bool _isConnected = false;
  int? _rssi;

  int idx_tx = 1;
  int idx_rx = 0;

  List<String> msg = [];

  int patchState = 0;
  double battery = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    device = context.read<BLEInfo>().device;
    service = context.read<BLEInfo>().service;
    characteristic = service.characteristics;

    msg.add("START!");

    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      switch(state){
        case BluetoothConnectionState.connected : _isConnected = true; break;
        case BluetoothConnectionState.disconnected: _isConnected = false; break;
        default: _isConnected = false; break;
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    switch (characteristic.first.uuid.toString().toUpperCase()){
      case rx: idx_tx = 1; idx_rx = 0;
      if (kDebugMode) {
        print("rx = ${characteristic[idx_rx].uuid.toString().toUpperCase()}\ntx = ${characteristic[idx_tx].uuid.toString().toUpperCase()}");
      }
      break;
      case tx: idx_tx = 0; idx_rx = 1;
      if (kDebugMode) {
        print("rx = ${characteristic[idx_rx].uuid.toString().toUpperCase()}\ntx = ${characteristic[idx_tx].uuid.toString().toUpperCase()}");
      }
      break;
      default:
        if (kDebugMode) {
          print("characteristic doesn't match any");
        }
        Navigator.pop(context);
        break;
    }

    characteristic[idx_tx].setNotifyValue(true);
    if (kDebugMode) {
      print("tx = ${characteristic[idx_tx].uuid.toString().toUpperCase()}\nset notify");
    }

    _lastValueSubscription = characteristic[idx_tx].lastValueStream.listen((value) {
      String convertedStr = utf8.decode(value).trimRight();

      if(utf8.decode(value).trim() != ""){
        msg.insert(0, convertedStr);
      }

      if (kDebugMode) {
        int count = 0;
        print("value : $convertedStr");
        print("printing msg");
        for(var element in msg){
          count++;
          print("$count : $element");
        }
        print("heard or listening");
      }

      if (mounted) {
        setState(() {});
      }
    });

    checking();

  }

  Future write(String text) async {
    try {
      // TODO : _textCnt.text cmd 확인 절차
      text += "\r";
      await characteristic[idx_rx].write(utf8.encode(text), withoutResponse: characteristic[idx_rx].properties.writeWithoutResponse);

      if (kDebugMode) {
        print("[HomeScreen] wrote: ${text}");
      }
    } catch (e) {
      if(kDebugMode){
        print("[HomeScreen] wrote error\nError: $e");
      }
    }
  }

  String timeStamp(){
    DateTime now = DateTime.now();
    String formattedTime = DateFormat.Hms().format(now);
    return formattedTime;
  }

  void checking(){
    Future.delayed(const Duration(seconds: 3),(){
      write("St");
      if(msg[0] == "Ready") {
        patchState = 1;
      } else {
        patchState = -1;
      }
    });
    if(mounted){
      setState(() {

      });
    }


    Future.delayed(const Duration(seconds: 6),(){
      write("status1");
      if(msg[0].contains("1")) {
        patchState = 2;
      } else {
        patchState = -2;
      }
    });
    if(mounted){
      setState(() {

      });
    }


    Future.delayed(const Duration(seconds: 9), (){
      write("Sn");
      if(msg[0].contains("Tn")) {
        String result = msg[0].replaceAll(RegExp('\\D'), "");
        battery = double.parse(result);
        battery /= 40;
        battery = battery.round() as double;
      } else {
        patchState = -2;
      }
    });
    if(mounted){
      setState(() {

      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),

      body: Consumer<BLEInfo>(
        builder: (context, provider, child){
          return Center(
            child: Column(
              children: [
                const Text("WELCOME HOME"),
                const Text("data"),
                Text("Device name: ${provider.device.platformName.toString()}"),
                Text("Service uuid : ${provider.service.uuid.toString().toUpperCase()}"),
                Text("msg: ${msg[0]}"),
                Text("battery: $battery%"),
                Text("checking status: $patchState"),
                _isConnected? OutlinedButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UARTScreen()));
                  },
                  child: const Text('UART Communication'),
                ):Container(),
              ],
            ),
          );
        }
      ),
    );
  }
}
