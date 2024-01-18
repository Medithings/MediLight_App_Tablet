import 'dart:async';
import 'dart:io';

import 'package:ble_uart/screens/home_screen.dart';
import 'package:ble_uart/utils/extra.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/scan_result_tile.dart';

class FirstConnectScreen extends StatefulWidget {
  const FirstConnectScreen({super.key});

  @override
  State<FirstConnectScreen> createState() => _FirstConnectScreenState();
}

class _FirstConnectScreenState extends State<FirstConnectScreen> {
  List<BluetoothDevice> _systemDevices = []; // FBP에서 제공하는 것 (BluetoothDevice)
  List<ScanResult> _scanResults = []; // FBP에서 제공하는 것 (ScanResult)
  bool _isScanning = false; // 초기값 false
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription; // Stream으로 받아오는 scan result list
  late StreamSubscription<bool> _isScanningSubscription; // Stream으로 bool 값을 가지는 state

  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;

  bool _isDiscoveringServices = false;
  final List<BluetoothService> _services = [];

  late Route route;
  late SharedPreferences pref;

  final String suid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; // nordic uart service uuid

  @override
  void initState() {
    // TODO: implement initState
    onScan();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) { // Scan result 를 listen
      // before : _scanResults = results

      // after : 이름에 Bladder 또는 Medi가 있을 때 Scan result에 저장
      _scanResults.clear();

      for (var element in results) {
        if(element.device.platformName.contains("Bladder") || element.device.platformName.contains("MEDi")){
          if(_scanResults.indexWhere((x) => x.device.remoteId == element.device.remoteId) < 0){
            _scanResults.add(element);
          }
        }
      }

      if (mounted) { // mounted 가 true 일 때 setState 를 해주는 것이 올바름
        setState(() {}); // set state
      }

    }, onError: (e) { // 에러 발생 시
      if(kDebugMode){
        print("[FirstConnectScreen] something went wrong while scanning on the initial state\nError: $e");
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) { // is scanning 을 listen
      _isScanning = state; // listen 해서 받아온 state 를 _isScanning 에 복사
      if (mounted) { // mounted?
        setState(() {}); // set state
      }
    });

    super.initState();
  }

  @override
  void dispose() { // dispose 하면 모든 subscription (listen 하는 것) 중지
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScan() async { // Scan button pressed
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      if(kDebugMode){
        print("[FirstConnectScreen] something went wrong while onScan-systemDevices is done\nError: $e");
      }
    }
    try {
      // android is slow when asking for all advertisements,
      // so instead we only ask for 1/8 of them
      int divisor = Platform.isAndroid ? 8 : 1;
      _scanResults.clear();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5), continuousUpdates: true, continuousDivisor: divisor);
    } catch (e) {
      if(kDebugMode){
        print("[FirstConnectScreen] something went wrong while onScan-startScan is done\nError: $e");
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      if (kDebugMode) {
        print("[FirstConnectScreen] something went wrong while onStopPressed-stopScan is done\nError: $e");
      }
    }
  }

  void onConnectPressed(BluetoothDevice device) async{
    try{
      await device.connectAndUpdateStream();
      if (kDebugMode) {
        print("[FirstConnectScreen] onConnectPressed - device: ${device.platformName}");
      }
      setSPRemoteId(device.remoteId.str);
    }catch(e){
      if (kDebugMode) {
        print("[FirstConnectScreen] something went wrong while onConnectPressed-connectAndUpdateStream is done\nError: $e");
      }
    }

    // try{
    //   await device.connect(mtu: null, autoConnect: true);
    // }catch(e){
    //   if (kDebugMode) {
    //     print("[FirstConnectScreen] something went wrong while onConnectPressed-connect is done\nError: $e");
    //   }
    // }

    try{
      for(var element in await device.discoverServices()){
        if(element.uuid.toString().toUpperCase() == suid) _services.add(element);
      }
      if(kDebugMode){
        print("[FirstConnectScreen] onConnectPressed - service uuid : ${_services.first.uuid.toString().toUpperCase()}");
      }
    }catch(e){
      if(kDebugMode){
        print("[FirstConnectScreen] something went wrong while onConnectPressed-discoverService is done\nError: $e");
      }
    }

    // TODO: device_screen에서 함수 불러오고 shared preferences의 registered를 true
    route = MaterialPageRoute(builder: (context) => HomeScreen(device: device, service: _services.first));
    pref = await SharedPreferences.getInstance();
    pref.setBool('registered', true);
    goHome();
  }

  void goHome(){
    Navigator.pushReplacement(context, route);
  }

  Future setSPRemoteId(String remoteId) async{
    pref = await SharedPreferences.getInstance();
    pref.setString('remoteId', remoteId);
    if(kDebugMode){
      print("[FirstConnectScreen] remoteId: $remoteId saved");
    }
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
        onPressed: onScan,
        child: const Text("SCAN"),
      );
    }
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .map(
          (r) => ScanResultTile(
        result: r,
        onTap: () => onConnectPressed(r.device),
      ),
    )
        .toList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finding Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: <Widget>[
            // no need system devices
            // ..._buildSystemDeviceTiles(context),
            ..._buildScanResultTiles(context),
          ],
        ),
      ),
      floatingActionButton: buildScanButton(context),
    );
  }
}
