import 'dart:async';
import 'dart:io';

import 'package:ble_uart/screens/bottom_navigation_screen.dart';
import 'package:ble_uart/utils/back_ground_service.dart';
import 'package:ble_uart/utils/extra.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/ble_info.dart';

class BetweenScreen extends StatefulWidget {
  const BetweenScreen({super.key});

  @override
  State<BetweenScreen> createState() => _BetweenScreenState();
}

class _BetweenScreenState extends State<BetweenScreen> {

  final List<ScanResult> _scanResults = []; // FBP에서 제공하는 것 (ScanResult)
  List<BluetoothDevice> patch = []; // FBP에서 제공하는 것 (BluetoothDevice)
  final List<BluetoothService> _services = [];
  late List<BluetoothCharacteristic> characteristics;
  late Route route = MaterialPageRoute(builder: (context) => const BottomNavigationScreen());

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription; // Stream으로 받아오는 scan result list

  static const String suid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; // Nordic service uid

  int checking = 0; // 1: patch found, 2: scanning done, 3: matched service found, (home에서) 4: matched characteristics found, (home에서) 5: ble communication testing went good

  late SharedPreferences pref;
  String remoteIdSaved="";

  @override
  void initState() {
    // TODO: implement initState
    Background.stopFlutterBackgroundService();
    onScan();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) { // Scan result 를 listen
      // before : _scanResults = results

      // after : 이름에 Bladder 또는 Medi가 있을 때 Scan result에 저장
      _scanResults.clear();

      for (var element in results) {
        if(element.device.remoteId.str == remoteIdSaved){
          if(kDebugMode){
            print("[BetweenScreen] remoteID: ${element.device.remoteId.str}\ndevice name:${element.device.platformName}");
          }
          if(_scanResults.indexWhere((x) => x.device.remoteId == element.device.remoteId) < 0){
            onStop();
            pref.setString("patchName", element.device.platformName);
            _scanResults.add(element);
            patch.add(element.device);
            storingDevice(element.device);
            onConnect(patch.first);
          }
        }
      }

      if (mounted) { // mounted 가 true 일 때 setState 를 해주는 것이 올바름
        setState(() {
          checking = 1;
        }); // set state
      }

    }, onError: (e) { // 에러 발생 시
      if(kDebugMode){
        print("[FirstConnectScreen] something went wrong while scanning on the initial state\nError: $e");
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scanResultsSubscription.cancel();
    super.dispose();
  }

  Future onScan() async {
    await getRemoteId();

    try {
    } catch (e) {
      if(kDebugMode){
        print("[BetweenScreen] something went wrong while onScan-systemDevices is done\nError: $e");
      }
    }

    try {
      // android is slow when asking for all advertisements,
      // so instead we only ask for 1/8 of them
      int divisor = Platform.isAndroid ? 8 : 1;
      _scanResults.clear();
      await FlutterBluePlus.startScan(continuousUpdates: true, continuousDivisor: divisor);
    } catch (e) {
      if(kDebugMode){
        print("[BetweenScreen] something went wrong while onScan-startScan is done\nError: $e");
      }
    }
    if (mounted) {
      setState(() {
        checking = 2;
      });
    }

  }

  void onConnect(BluetoothDevice device) async{
    try{
      await device.connectAndUpdateStream();
      if (kDebugMode) {
        print("[BetweenScreen] on connecting - device: ${device.platformName}");
      }

    }catch(e){
      if (kDebugMode) {
        print("[BetweenScreen] something went wrong while onConnect-connectAndUpdateStream is done\nError: $e");
      }
    }

    try{
      for(var element in await device.discoverServices()){
        if(element.uuid.toString().toUpperCase() == suid){
          _services.add(element);
          storingService(element);
        }
      }
      if(kDebugMode){
        print("[BetweenScreen] onConnect - service uuid : ${_services.first.uuid.toString().toUpperCase()}");
      }
    }catch(e){
      if(kDebugMode){
        print("[BetweenScreen] something went wrong while onConnect-discoverService is done\nError: $e");
      }
    }

    // TODO: if registered is true goHome
    goHome();
  }

  void storingService(BluetoothService s){
    context.read<BLEInfo>().service = s;
  }

  void storingDevice(BluetoothDevice d){
    context.read<BLEInfo>().device = d;
  }

  void goHome(){
    Navigator.pushReplacement(context, route);
  }

  Future onStop() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      if (kDebugMode) {
        print("[BetweenScreen] something went wrong while onStop-stopScan is done\nError: $e");
      }
    }
  }

  Future getRemoteId() async {
    pref = await SharedPreferences.getInstance();

    try{
      setState(() {
        remoteIdSaved = pref.getString("remoteId")!;
        if (kDebugMode) {
          print("[BetweenScreen] getRemoteId remoteId: $remoteIdSaved");
        }
      });
    }catch(e){
      if (kDebugMode) {
        print("[BetweenScreen] getRemoteId error: $e");
      }
    }
  }

  // Widget screen(){
  //   switch(checking){
  //     case 1: return const Scaffold(body: Center(child: Text("number 1"),));
  //     case 2: return const Scaffold(body: Center(child: Text("number 2"),));
  //     case 3: return const BottomNavigationScreen();
  //     default: return const Scaffold(body: Center(child: Text("number 0"),));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Auto Connection"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 1,),
            Lottie.asset("assets/lottie/bluetooth_connection.json"),
            const SizedBox(height: 20,),
            const Text("Wait for a moment"),
            Text("checking : $checking"),
            const Spacer(flex: 3,),
          ],
        ),
      ),
    );
  }
}
