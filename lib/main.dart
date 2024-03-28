// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:ble_uart/screens/alarm_alert_screen.dart';
import 'package:ble_uart/screens/between_screen.dart';
import 'package:ble_uart/screens/onboarding_screen.dart';
import 'package:ble_uart/utils/back_ground_service.dart';
import 'package:ble_uart/utils/ble_info_provider.dart';
import 'package:ble_uart/utils/shared_prefs_utils.dart';
import 'package:ble_uart/utils/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'screens/bluetooth_off_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Alarm.init(showDebugLogs: true);
  await SharedPrefsUtil().init();
  print("db = DatabaseModel");
  final db = DatabaseModel();
  print("db get database");
  await db.database;

  KakaoSdk.init(nativeAppKey: '5334e091dd18acc59eeaffac5c5f5959'); // kako native appp
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true); // Log level 을 verbose 로 설정, syntax color on

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_)=> BLEInfoProvider()),
      ],
      child: const FlutterBlueApp(),
    ),
  );
}

//
// This widget shows BluetoothOffScreen or
// ScanScreen depending on the adapter state
//
class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown; // state unknown for IOS
  bool registered = false;
  String name = "";
  bool ringing = false;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription; // stream state subscription
  late SharedPreferences pref;

  late List<AlarmSettings> alarms = [];
  static StreamSubscription<AlarmSettings>? subscription;

  late String userName;
  late String? guardian;

  @override
  void initState() { // Identify whether the adapter is connected (listening)
    prefGetter();
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state; // listen to current state
      if (mounted) { // if the adapter is connected then setState
        setState(() {});
      }
    });

    // AlarmStorage.init();
    // loadAlarms();
    //
    // subscription ??= Alarm.ringStream.stream.listen((alarmSettings)
    //   => navigateToRingScreen(alarmSettings),
    // );

    // if (Alarm.android) {
    //   checkAndroidNotificationPermission();
    // }

  }



  @override
  void dispose() { // subscription cancel
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  // TODO: return Wigdet 함수 where the device has stored data (name, age, height, weight, and gender)
  void prefGetter() async {
     pref = await SharedPreferences.getInstance();

    try{
      registered = pref.getBool("registered")!;
      name = pref.getString("name")!;

      if(pref.containsKey("ringing")){
        setState(() {
          ringing = pref.getBool("ringing")!;
        });
      }
    }catch(e){
      registered = false;
      if (kDebugMode) {
        print("error : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // Background.startFlutterBackgroundService(() async{
    //   Background.alarmSendEmail();
    // });
    // NO NEED
    // Widget screen = _adapterState == BluetoothAdapterState.on
    //     ? ScanScreen() // if the device's bluetooth is on then widget to ScanScreen()
    //     : BluetoothOffScreen(adapterState: _adapterState); // else widget to BluetoothOffScreen() with current state

    // prefGetter();
    Widget firstScreen(){
      if(registered){ // TODO: ScanScreen should be replaced with home page
        return _adapterState == BluetoothAdapterState.on? const BetweenScreen() : BluetoothOffScreen(adapterState: _adapterState);
      } else{
        return const OnBoardingScreen();
      }
    }

    if (kDebugMode) {
      print("[print k debug] $name");
    }

    return MaterialApp(
      color: Colors.lightBlue,
      home: firstScreen(),
      navigatorObservers: [BluetoothAdapterStateObserver()], // Navigate Observers
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light,),
      darkTheme: ThemeData(brightness: Brightness.light),
      themeMode: ThemeMode.light,
      routes: {
        '/betweenScreen': (context) => const BetweenScreen(),
      },
    );
  }
}

//
// This observer listens for Bluetooth Off and dismisses the DeviceScreen
//
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription; // adapter bluetooth state

  // navigator push를 했는데 그게 DeviceScreen에 접근하면 adapterState를 통해 핸드폰 블루투스 state를 listen 함
  // 그 상태에서 만약 bluetooth가 꺼져있으면 pop
  @override
  void didPush(Route route, Route? previousRoute) { // if the navigator did push (route, previous route)
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') { // if the route name is '/DeviceScreen'
      // Start listening to Bluetooth state changes when a new route is pushed
      _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          // Pop the current route if Bluetooth is off
          navigator?.pop();
        }
      });
    }
  }

  // navigator pop을 하면 adapter state subscribe를 취소하고 null로 변경
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') { // if the route name is '/DeviceScreen'
      // Cancel the subscription when the route is popped
      _adapterStateSubscription?.cancel();
      _adapterStateSubscription = null;
    }
  }
}
