import 'dart:async';
import 'dart:convert';

import 'package:ble_uart/widgets/patch_info_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../utils/ble_info_provider.dart';
import 'bottom_navigation_screen.dart';

final  navigationBar = bottomNavGKey.currentWidget;

class PatchInfoScreen extends StatefulWidget {
  const PatchInfoScreen({super.key});

  @override
  State<PatchInfoScreen> createState() => _PatchInfoScreenState();
}

class _PatchInfoScreenState extends State<PatchInfoScreen> {
  static const String rx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write data to the rx characteristic to send it to the UART interface.
  static const String tx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Enable notifications for the tx characteristic to receive data from the application.

  late BluetoothDevice device;
  late BluetoothService service;

  int idx_tx = 1;
  int idx_rx = 0;

  List<String> msg = [];

  late StreamSubscription<List<int>> _lastValueSubscription;
  late List<BluetoothCharacteristic> characteristic;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    device = context.read<BLEInfoProvider>().device;
    service = context.read<BLEInfoProvider>().service;
    characteristic = context.read<BLEInfoProvider>().service.characteristics;

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

      if(convertedStr.contains("Tr")){
        device.disconnect();
        Navigator.of(context).pop();
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future resetCmdWrite() async {
    try {
      String resetCmd = "Sr\r";
      await characteristic[idx_rx].write(utf8.encode(resetCmd), withoutResponse: characteristic[idx_rx].properties.writeWithoutResponse);
    } catch (e) {
      if(kDebugMode){
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patch Information"),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 50,),

          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black12,
            ),
            child: const Padding(
              padding: EdgeInsets.only(left: 20, top: 20,),
              child: Text(
                "Caution\nIf you reset the path, application also needs to be reset.\nAfter resetting the patch, please delete the app and reinstall.\nAlso, you need to delete the patch in system settings.",
                style: TextStyle(color: Colors.black54, fontSize: 17, ),
              ),
            ),
          ),

          const SizedBox(height: 80,),

          Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                bottom: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
              ),
            ),
            child: PatchInfoTile(
              info: device.platformName,
              title: "Patch name",
            ),
          ),

          const SizedBox(height: 30,),

          InkWell(
            onTap: (){
              GestureDetector(
                onTap: (){
                FocusScope.of(context).unfocus();
              });

              showModalBottomSheet(
                context: context,
                builder: (BuildContext context){
                  return Container(
                    height: 180,
                    color: Colors.black.withOpacity(.6),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: (){
                            resetCmdWrite();
                          },
                          child: Container(
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: const Center(
                              child: Text("DELETE PATCH", style: TextStyle(fontSize: 18, color: Colors.red,),),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10,),

                        InkWell(
                          onTap: (){
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: const Center(
                              child: Text("Cancel", style: TextStyle(fontSize: 18, color: Colors.blue,),),
                            ),
                          ),
                        ),

                        const Spacer(flex: 1,),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                  bottom: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                ),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Row(
                children: [
                  Spacer(flex: 1,),
                  Text(
                    "Delete Patch",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                    ),
                  ),
                  Spacer(flex: 1,),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
