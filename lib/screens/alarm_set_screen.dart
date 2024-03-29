import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/service/alarm_storage.dart';

import 'package:ble_uart/screens/alarm_alert_screen.dart';
import 'package:ble_uart/widgets/alarm_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_edit_screen.dart';


class AlarmSetScreen extends StatefulWidget {
  const AlarmSetScreen({Key? key}) : super(key: key);

  @override
  State<AlarmSetScreen> createState() => _AlarmSetScreenState();
}

class _AlarmSetScreenState extends State<AlarmSetScreen> {
  late List<AlarmSettings> alarms = [];
  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    getSharedPreferencedData();
    print("[alarm_set_screen] get Shared Preferenced Data() complete");

    super.initState();
    print("[alarm_set_screen] super init state done");

    if (Alarm.android) {
      checkAndroidNotificationPermission();
    }

    AlarmStorage.init();
    loadAlarms();

    print("[alarm_set_screen] load alarm done");

    // subscription ??= Alarm.ringStream.stream.listen(
    //       (alarmSettings) => navigateToRingScreen(alarmSettings),
    // );

    print("[alarm_set_screen] subscription done");
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

  void getSharedPreferencedData() async {
    try{
      await SharedPreferences.getInstance();
    }catch(e){
      if (kDebugMode) {
        print("error");
      }
    }
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

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await showModalBottomSheet<bool?>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.75,
            child: AlarmEditScreen(alarmSettings: settings),
          );
        });

    if (res != null && res == true) loadAlarms();
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

  Future<void> checkAndroidExternalStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      alarmPrint('Requesting external storage permission...');
      final res = await Permission.storage.request();
      alarmPrint(
        'External storage permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("start building");
    loadAlarms();

    return Scaffold(
      appBar: AppBar(
        title: const Text("    Alarm", style: TextStyle(fontSize: 35,),),
        toolbarHeight: 120,
        centerTitle: false,
        shape: const Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: alarms.isNotEmpty
            ? ListView.separated(
              itemCount: alarms.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 50.0, left: 50,),
                child: Divider(height: 1),
              ),
              itemBuilder: (context, index) {
                return AlarmTile(
                  key: Key(alarms[index].id.toString()),
                  title: TimeOfDay(
                    hour: alarms[index].dateTime.hour,
                    minute: alarms[index].dateTime.minute,
                  ).format(context),
                  onPressed: () => navigateToAlarmScreen(alarms[index]),
                  onDismissed: () {
                    Alarm.stop(alarms[index].id).then((_) => loadAlarms());
                  },
                );
              },
            )
            : const Center(
              child: Text(
                "No alarms set",
                style: TextStyle(
                  fontSize: 35,
                ),
              ),
            ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 30,),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // AlarmShortcutButton(refreshAlarms: loadAlarms),
            FloatingActionButton.large(
              onPressed: () => navigateToAlarmScreen(null),
              child: const Icon(Icons.alarm_add_rounded, size: 50),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}