import 'dart:async';
import 'dart:convert';

import 'package:ble_uart/utils/extra.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

import '../utils/snackbar.dart';
import 'device_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String suid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; // nordic uart service uuid
  static const String rx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write data to the rx characteristic to send it to the UART interface.
  static const String tx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Enable notifications for the tx characteristic to receive data from the application.

  List<BluetoothDevice> _systemDevices = []; // FBP에서 제공하는 것 (BluetoothDevice)
  late BluetoothDevice patch;

  bool connected = false;
  bool _isDiscoveringServices = false;

  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;

  late List<BluetoothCharacteristic> characteristic;

  late StreamSubscription<List<int>> _lastValueSubscription;

  int idx_tx = 1;
  int idx_rx = 0;

  List<String> msg = [];

  String startCommand = "St\r";
  String receiveStartCommand = "";
  bool wrGood = false;


  @override
  void initState() {
    // TODO: implement initState
    findSystemDevice();
    onConnect();

    if(connected){

      _connectionStateSubscription = patch.connectionState.listen((state) async {
        _connectionState = state;
        if (state == BluetoothConnectionState.connected) {
          patch.connect(mtu:null, autoConnect: true);
          await onDiscoverServices();
        }
        if (mounted) {
          setState(() {});
        }
      });

      switch (characteristic.first.uuid.toString().toUpperCase()){
        case rx:
          setState(() {
            idx_tx = 1; idx_rx = 0;
          });

          if (kDebugMode) {
            print("rx = ${characteristic[idx_rx].uuid.toString().toUpperCase()}\ntx = ${characteristic[idx_tx].uuid.toString().toUpperCase()}");
          }
          break;

        case tx:
          setState(() {
            idx_tx = 0; idx_rx = 1;
          });

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

      // tx channel listen 해서 _lastValueSubscription 에 넣음 + msg 에 decode 해서 add
      _lastValueSubscription = characteristic[idx_tx].lastValueStream.listen((value) {
        String convertedStr = utf8.decode(value).trimRight();

        if(utf8.decode(value).trim() != ""){
          setState(() {
            msg.insert(0, convertedStr);
          });
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

    }

    super.initState();
  }

  Future findSystemDevice() async { // Scan button pressed
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;

      for(var element in _systemDevices){
        if(element.platformName.contains("Bladder") || element.platformName.contains("MEDi")){
          setState(() {
            patch = element;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("[HomeScreen] System device error : $e");
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onConnect() async {
    try{
      await patch.connectAndUpdateStream();
    }catch(e){
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.success.index) {
        // ignore connections canceled by the user
        setState(() {
          connected = true;
        });
      } else if(e is FlutterBluePlusException && e.code == FbpErrorCode.deviceIsDisconnected.index){
        setState(() {
          connected = false;
        });
      } else if(e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index){
        setState(() {
          connected = false;
        });
      }
      else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
        if (kDebugMode) {
          print("[HomeScreen] system device connection error : $e");
        }
      }
    }
  }

  Future onDiscoverServices() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      for(var element in await patch.discoverServices()){
        if(element.uuid.toString().toUpperCase() == suid){
          setState(() {
            characteristic = element.characteristics;
          });
        }
      }
      // before : get all the services
      // _services = await widget.device.discoverServices();
      // Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e), success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  String timeStamp(){
    DateTime now = DateTime.now();
    String formattedTime = DateFormat.Hms().format(now);
    return formattedTime;
  }

  Future wrStartCommand() async{
    try{
      await characteristic[idx_rx].write(utf8.encode(startCommand), withoutResponse: characteristic[idx_rx].properties.writeWithoutResponse);

      if (kDebugMode) {
        print("wrote: ${timeStamp()}:\t$startCommand");
      }

      Future.delayed(
          const Duration(milliseconds: 600)).then(
            (value){
              setState(() {
                receiveStartCommand = msg[0];
                if(receiveStartCommand.contains("Ready")){
                  setState(() {
                    wrGood = true;
                  });
                }
              });
            }
      );
      
    }catch(e){
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
    }
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

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
            Text(msg[0]),
          ],
        ),
      ),
    );
  }
}
