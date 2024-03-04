import 'dart:async';
import 'dart:io';

import 'package:ble_uart/screens/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../main.dart';
import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../utils/extra.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key,}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

// TODO 1 : STREAM SUBSCRIPTION 공부 (STREAM 이랑 같은 개념, 조금 더 깊이 있게 공부) * DONE

// TODO 2 : mounted 공부 * DONE
/*
* mounted : whether this State object is currently in a tree.
*
* After creating a State object and before calling initState,
* the framework "mounts" the State object by associating it with a BuildContext.
* The State object remains mounted until the framework calls dispose,
* after which time the framework will never ask the State object to build again.
*
* It is an error to call setState unless mounted is true.
* https://api.flutter.dev/flutter/widgets/State/mounted.html
*
* bool get mounted => _element != null;
*/


class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = []; // FBP에서 제공하는 것 (BluetoothDevice)
  final List<ScanResult> _scanResults = []; // FBP에서 제공하는 것 (ScanResult)
  bool _isScanning = false; // 초기값 false
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription; // Stream으로 받아오는 scan result list
  late StreamSubscription<bool> _isScanningSubscription; // Stream으로 bool 값을 가지는 state

  @override
  void initState() {
    super.initState();

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
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false); // 스낵바 팝업
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) { // is scanning 을 listen
      _isScanning = state; // listen 해서 받아온 state 를 _isScanning 에 복사
      if (mounted) { // mounted?
        setState(() {}); // set state
      }
    });
  }

  @override
  void dispose() { // dispose 하면 모든 subscription (listen 하는 것) 중지
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  // Future: currently doesn't exist, but on future it will be used (like a box which contains something)
  // https://velog.io/@jintak0401/FlutterDart-에서의-Future-asyncawait
  Future onScanPressed() async { // Scan button pressed
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
    }
    try {
      // android is slow when asking for all advertisements,
      // so instead we only ask for 1/8 of them
      int divisor = Platform.isAndroid ? 8 : 1;
      _scanResults.clear();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10), continuousUpdates: true, continuousDivisor: divisor);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
    });
    // TODO: device_screen에서 함수 불러오고 shared preferences의 registered를 true
    final navigator = Navigator.of(context);
    navigator.pushReplacement(MaterialPageRoute(builder: (context) => const FlutterBlueApp(),),);
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
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
          onPressed: onScanPressed,
          child: const Text("SCAN"),
      );
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices
        .map(
          (d) => SystemDeviceTile( // (widget > system_device_tile.dart)
            device: d,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeviceScreen(device: d),
                settings: const RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
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
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find Devices'),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const SettingsScreen(),),),
              icon: const Icon(Icons.settings),
            ),
          ],
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
      ),
    );
  }
}
