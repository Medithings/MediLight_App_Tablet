import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

late SharedPreferences pref;
String remoteIdSaved="";
final List<ScanResult> _scanResults = [];

const notificationChannelId = "mediLight_foreground";
const notificationId = 888;

Future<void> initializeService() async{
  final service = FlutterBackgroundService();

  if(!Platform.isAndroid){
    return;
  }

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    "FOREGROUND SERVICE",
    description: "This channel is used for important notifications",
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if(Platform.isIOS||Platform.isAndroid){
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('launcher_notification'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: "MediLight App is running for connection",
      initialNotificationContent: "Tap to return to the app",
      foregroundServiceNotificationId: notificationId,
    ),

    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // TODO: 이후에 어떠한 시간적 주기마다 sj를 해서 받아온 값을 가지고 처리를 할 수 있기 때문에 write와 read는 놔두었다 (주석 처리된 것들)
  // Variables Using in Bluetooth Functionality
  List<BluetoothDevice> scannedDevicesList = <BluetoothDevice>[];
  StreamSubscription? streamSubscription;
  BluetoothDevice? gBleDevice;
  List<BluetoothService> gBleServices = <BluetoothService>[];
  StreamSubscription? subscription;
  StreamSubscription? subscriptionConnection;
  List<String> receivedDataList = <String>[];
  // String sendCharacteristicUuid = "";
  // String receiveCharacteristicUuid = "";
  // String dataForWrite = "";
  List<int> readValue = [];

  SharedPreferences getMethodsCall = await SharedPreferences.getInstance();
  await getMethodsCall.reload();

  String? deviceName = getMethodsCall.getString("patchName");
  String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";

  // This is getting values for scanning and connecting of specific device
  // final connectToDevice = getMethodsCall.getStringList('connectToDevice') ??
  //     <String>[];
  // deviceName = connectToDevice[1];
  // serviceUuid = connectToDevice[2];

  List<String> connectToDevice = [];
  connectToDevice.add(deviceName??"");
  connectToDevice.add(serviceUuid);

  // This is getting values to write value on specific device
  // final writeData = getMethodsCall.getStringList('writeData') ?? <String>[];
  // if (writeData.isNotEmpty) {
  //   sendCharacteristicUuid = writeData[1];
  //   dataForWrite = writeData[2];
  // }
  //
  // // This is getting values to read value on specific device
  // final readData = getMethodsCall.getStringList('readData') ?? <String>[];
  // if (readData.isNotEmpty) {
  //   receiveCharacteristicUuid = readData[1];
  // }

  // writeCharacteristic will write value on specific characteristic
  // void writeCharacteristic(String command) async {
  //   for (var serv in gBleServices) {
  //     if (serv.uuid.toString() == serviceUuid) {
  //       debugPrint("service match ${serv.uuid.toString()}");
  //       //service = serv;
  //       for (var char in serv.characteristics) {
  //         if (char.uuid.toString() == sendCharacteristicUuid) {
  //           debugPrint("char match ${char.uuid.toString()}");
  //           List<int> bytes = command.codeUnits;
  //           debugPrint("bytes are $bytes");
  //           await char.write(bytes);
  //           debugPrint("write success");
  //         }
  //       }
  //     }
  //   }
  // }
  //
  // //
  // void receiveCommandFromFirmware() async {
  //   for (var serv in gBleServices) {
  //     if (serv.uuid.toString() == serviceUuid) {
  //       debugPrint("service match in read ${serv.uuid.toString()}");
  //       for (var char in serv.characteristics) {
  //         if (char.uuid.toString() == receiveCharacteristicUuid) {
  //           debugPrint("char match in read ${char.uuid.toString()}");
  //           if (subscription != null) {
  //             debugPrint("Canceling stream");
  //             subscription!.cancel();
  //           }
  //           if (char.properties.notify == true) {
  //             await char.setNotifyValue(true);
  //             subscription = char.onValueReceived.listen((value) async {
  //               debugPrint("received value is $value");
  //               SharedPreferences preferences = await SharedPreferences
  //                   .getInstance();
  //               await preferences.reload();
  //               final log = preferences.getStringList('getReadData') ??
  //                   <String>[];
  //               log.add(value.toString());
  //             });
  //           } else {
  //             readValue = await char.read();
  //             debugPrint("read value is  $readValue");
  //             SharedPreferences preferences = await SharedPreferences
  //                 .getInstance();
  //             await preferences.reload();
  //             final log = preferences.getStringList('getReadData') ??
  //                 <String>[];
  //             log.add(readValue.toString());
  //             await preferences.setStringList('getReadData', log);
  //           }
  //         }
  //       }
  //     }
  //   }
  // }


  // scanningMethod() will scan devices and connect to specific device
  Future<void> scanningMethod() async {
    final isScanning = FlutterBluePlus.isScanningNow;
    if (isScanning) {
      await FlutterBluePlus.stopScan();
    }

    await FlutterBluePlus.stopScan();
    //Empty the Devices List before storing new value
    scannedDevicesList = [];
    gBleServices.clear();
    // servicesList.clear();
    receivedDataList.clear();

    await streamSubscription?.cancel();

    streamSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName.isNotEmpty &&
            !scannedDevicesList.contains(r.device)) {
          if (r.device.platformName == deviceName) {
            debugPrint("Device Name Matched ${r.device.platformName}");
            await streamSubscription?.cancel();
            scannedDevicesList.add(r.device);
            gBleDevice = r.device;

            await FlutterBluePlus.stopScan();
            try {
              await gBleDevice!.disconnect();
              await gBleDevice!.connect(autoConnect: false);
            } catch (e) {
              if (e.toString() != 'already_connected') {
                await gBleDevice!.disconnect();
              }
            } finally {
              gBleServices =
              await gBleDevice!.discoverServices();
              Future.delayed(const Duration(milliseconds: 500), () async {
                if (Platform.isAndroid) {
                  await gBleDevice!.requestMtu(200);
                }
              });
              Future.delayed(Duration.zero, () {
                debugPrint('Device Connected');
                //receiveCommandFromFirmware();
                subscriptionConnection = gBleDevice?.connectionState.listen((
                    BluetoothConnectionState state) async {
                  if (state == BluetoothConnectionState.disconnected) {
                    // 1. typically, start a periodic timer that tries to
                    //    reconnect, or just call connect() again right now
                    // 2. you must always re-discover services after disconnection!
                    debugPrint("${gBleDevice?.platformName} is disconnected");
                    subscription!.cancel();
                    scanningMethod();
                    subscriptionConnection!.cancel();
                  }
                });
              });
            }
          }
        }
      }
    },
    );
    await FlutterBluePlus.startScan();
  }

  if (connectToDevice.isNotEmpty) {
    scanningMethod();
  }

  // bring to foreground
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'COOL SERVICE',
          'Awesome ${DateTime.now()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'launcher_notification',
              ongoing: true,
            ),
          ),
        );

        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: "MediLight",
          content: "Running for connection",
        );
      }
    }

    print("FLUTTER BACKGROUND SERVICE: ${DateTime.now()}");

    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if(Platform.isAndroid){
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }
    if(Platform.isIOS){
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    /// you can see this log in logcat
    //debugPrint('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "readData": readValue.toString(),
      },
    );
  });
}

class Background {

  static const MethodChannel _channel = MethodChannel('ios_back_plugin');

  static Future<void> stopFlutterBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    } else {}
  }

  // This Function will start or initialize background service in ios and android
  static Future<void> startFlutterBackgroundService(Function()? backgroundFunction) async {
    if(Platform.isAndroid){
      try {
        // await initializeService();
        backgroundFunction!();
      } catch (e) {
        // print("Error executing in the background: $e");
      }
    }else{
      try {
        await _channel.invokeMethod('executeInBackground');
        backgroundFunction!();
      } catch (e) {
        // print("Error executing in the background: $e");
      }
    }
  }

  static Future<void> initialize() async {
    if(Platform.isAndroid){
      await initializeService();
    }else{
      await _channel.invokeMethod('executeInBackground');
    }
  }

  static Future<void> alarmSendEmail() async{
    StreamSubscription<AlarmSettings>? subscription;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String userName = pref.getString("name") ?? "No name";
    String guardian = pref.getString("guardianEmail") ?? "";

    subscription ??= Alarm.ringStream.stream.listen((alarmSettings) async {
      if(guardian == "") guardian = "medilightalert@gmail.com";

      final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': 'service_3gzs5mj',
          'template_id': 'template_h9e6z72',
          'user_id': 'DpL6M9GiRBZFBI1bh',
          'accessToken': '1-6LZXIKob51cgNkHjbmt',
          'template_params': {
            'user_name': userName,
            'send_to': guardian,
          },
        }),
      );
      print(response.body);
    });
  }

  // This method will write data on specific characteristic
  static Future<void> connectToDevice() async {

    SharedPreferences getMethodsCall = await SharedPreferences.getInstance();
    await getMethodsCall.reload();

    String deviceName = getMethodsCall.getString("patchName") as String;
    String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";

    if(Platform.isAndroid){
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final log = preferences.getStringList('connectToDevice') ?? <String>[];
      log.clear();
      log.add("connectToDevice");
      log.add(deviceName);
      log.add(serviceUuid);
      await preferences.setStringList('connectToDevice', log);
      await initializeService();
    }else{
      await _channel.invokeMethod('connectToDevice', {
        'deviceName': deviceName,
        'serviceUuid': serviceUuid,
      });
    }
  }

  // This method will read data on specific characteristic
  // static Future<String?> readData({
  //   String? serviceUuid,
  //   required String characteristicUuid
  // }) async {
  //   if(Platform.isAndroid){
  //     SharedPreferences preferences = await SharedPreferences.getInstance();
  //     await preferences.reload();
  //     final log = preferences.getStringList('readData') ?? <String>[];
  //     log.clear();
  //     log.add("readData");
  //     log.add(characteristicUuid);
  //     await preferences.setStringList('readData', log);
  //     return "";
  //   }else{
  //     final result = await _channel.invokeMethod('readData', {
  //       'serviceUuid' : serviceUuid,
  //       'characteristicUuid' : characteristicUuid
  //     });
  //
  //     // Assuming that the result is a String, you can replace String with the actual type.
  //     return result.toString();
  //   }
  // }
  //
  // This method will write data on specific characteristic
  // static Future<void> writeData({
  //   String? serviceUuid,
  //   required String characteristicUuid,
  //   required String data,
  // }) async {
  //   if(Platform.isAndroid){
  //     SharedPreferences preferences = await SharedPreferences.getInstance();
  //     await preferences.reload();
  //     final log = preferences.getStringList('writeData') ?? <String>[];
  //     log.clear();
  //     log.add("writeData");
  //     log.add(characteristicUuid);
  //     log.add(data);
  //     await preferences.setStringList('writeData', log);
  //   }else{
  //     try {
  //       await _channel.invokeMethod('writeData', {
  //         'serviceUuid' : serviceUuid,
  //         'characteristicUuid' : characteristicUuid,
  //         'data': data
  //       });
  //     } catch (e) {
  //       // print("Error executing in the writing value: $e");
  //     }
  //   }
  // }
  // This method will delete all the data which is stored on the result of read characteristic
  // static Future<void> clearReadStorage() async {
  //   try {
  //     SharedPreferences preferences = await SharedPreferences.getInstance();
  //     await preferences.reload();
  //     final log = preferences.getStringList('getReadData') ?? <String>[];
  //     log.clear();
  //     // print("clear read storage");
  //   } catch (e) {
  //     // print("Error to clear the read storage: $e");
  //   }
  // }
  //
  // static Future<List<String>?> getReadDataAndroid() async {
  //   try {
  //     SharedPreferences preferences = await SharedPreferences.getInstance();
  //     await preferences.reload();
  //     final log = preferences.getStringList('getReadData') ?? <String>[];
  //     return log;
  //     // print("clear read storage");
  //   } catch (e) {
  //     // print("Error to clear the read storage: $e");
  //     return null;
  //   }
  // }
}

