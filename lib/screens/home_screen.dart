import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ble_uart/screens/ai_screen.dart';
import 'package:ble_uart/screens/between_screen.dart';
import 'package:ble_uart/screens/uart_screen.dart';
import 'package:ble_uart/utils/ble_info.dart';
import 'package:ble_uart/utils/extra.dart';
import 'package:ble_uart/utils/parsing_measured.dart';
import 'package:cupertino_battery_indicator/cupertino_battery_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../main.dart';
import '../utils/database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key,});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin<HomeScreen> {

  @override
  bool get wantKeepAlive => true;

  static const String rx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write data to the rx characteristic to send it to the UART interface.
  static const String tx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Enable notifications for the tx characteristic to receive data from the application.

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<List<int>> _lastValueSubscription;

  late BluetoothDevice device;
  late BluetoothService service;
  late List<BluetoothCharacteristic> characteristic;

  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  late Route route = MaterialPageRoute(builder: (context) => const BetweenScreen());

  bool _isConnected = false;
  int? _rssi;

  int idxTx = 1;
  int idxRx = 0;

  List<String> msg = [];
  List<String> tjmsg = [];

  int patchState = 0;
  double battery = 0.0;

  String todayString = "";

  bool measuring = false;
  bool didInitialSet = false;
  bool areYouGoingToWrite = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(kDebugMode){
      print("[HomeScreen] !!Init state start!!");
      print("[HomeScreen] patch state is $patchState");
    }

    todayString = DateFormat.yMMMd().format(DateTime.now());

    device = context.read<BLEInfo>().device;
    service = context.read<BLEInfo>().service;
    characteristic = service.characteristics;

    msg.clear();
    tjmsg.clear();

    didInitialSet = false;
    areYouGoingToWrite = false;

    if(_connectionState == BluetoothConnectionState.disconnected){
      if(kDebugMode){
        print("[HomeScreen] The device is disconnected");
      }
      device.connectAndUpdateStream();
    }
    // msg.add("START!");

    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;

      if(kDebugMode){
        print("[HomeScreen] initState() state: $state");
      }

      if(state == BluetoothConnectionState.disconnected){
        setState(() {
          patchState = 0; // TODO: 0으로 바꿔기
          battery = 0.0;
        });
        device.connectAndUpdateStream();
        _lastValueSubscription.pause();
        if(kDebugMode){
          print("[HomeScreen] patchState = $patchState");
          print("[HomeScreen] _lastValueSubscription paused?: ${_lastValueSubscription.isPaused == true}");
        }
      }
      if(state == BluetoothConnectionState.connected){
        if(kDebugMode){
          print("-------[HomeScreen] _connectionState listeningToChar()-------");
        }
        listeningToChar();
        if(kDebugMode){
          print("-------[HomeScreen] _connectionState listeningToChar() done-------");
        }
        if(kDebugMode){
          print("-------[HomeScreen] _connectionState _lastValueSubscription.resume-------");
        }
        _lastValueSubscription.resume();
        if(kDebugMode){
          print("-------[HomeScreen] _connectionState _lastValueSubscription.resume done-------");
        }
        if(kDebugMode){
          print("-------[HomeScreen] _connectionState reConnect()-------");
        }
        reConnect();
        if(kDebugMode){
          print("-------[HomeScreen] _connectionState reConnect() done-------");
        }
        if(kDebugMode){
          print("[HomeScreen] _lastValueSubscription paused?: ${_lastValueSubscription.isPaused == true}");
        }
      }
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
  }

  void listeningToChar(){
    service = context.read<BLEInfo>().service;

    if(kDebugMode){
      print("[HomeScreen] listeningToChar(): service uid is ${service.uuid.toString().toUpperCase()}");
    }
    characteristic = service.characteristics;
    if(kDebugMode){
      print("[HomeScreen] listeningToChar(): first element of char is ${characteristic[0].uuid.toString().toUpperCase()}");
    }

    switch (characteristic.first.uuid.toString().toUpperCase()){
      case rx: idxTx = 1; idxRx = 0;
      if (kDebugMode) {
        print("rx = ${characteristic[idxRx].uuid.toString().toUpperCase()}\ntx = ${characteristic[idxTx].uuid.toString().toUpperCase()}");
      }
      break;
      case tx: idxTx = 0; idxRx = 1;
      if (kDebugMode) {
        print("rx = ${characteristic[idxRx].uuid.toString().toUpperCase()}\ntx = ${characteristic[idxTx].uuid.toString().toUpperCase()}");
      }
      break;
      default:
        if (kDebugMode) {
          print("characteristic doesn't match any");
        }
        Navigator.pop(context);
        break;
    }

    device.discoverServices();
    if(kDebugMode){
      print("[HomeScreen] listeningToChar(): Before set notify value discover services");
    }

    _lastValueSubscription = characteristic[idxTx].lastValueStream.listen((value) async {
      String convertedStr = utf8.decode(value).trimRight();

      if(kDebugMode){
        print("[!!LastValueListen!!] listen string: $convertedStr");
      }

      checking(convertedStr);

      if (mounted) {
        setState(() {});
      }
    });

    device.cancelWhenDisconnected(_lastValueSubscription);

    characteristic[idxTx].setNotifyValue(true);

    if (kDebugMode) {
      print("tx = ${characteristic[idxTx].uuid.toString().toUpperCase()}\nset notify");
    }

  }

  void checking(String msgString){
    if(kDebugMode){
      print("-------[HomeScreen] checking start-------");
      print("[HomeScreen] checking() current patch state: $patchState");
    }

    if(msgString != ""){
      msg.add(msgString);

      switch(patchState){
        case -1: {
          if(msgString.contains("Ready")){
            setState(() {
              patchState = 1;
            });
            write("Sn");
          }
          else{
            write("St");
            setState(() {
              patchState = 0;
            });
          }
        }
        break;

        case 0: {
          if(msgString.contains("Ready")) {
            setState(() {
              patchState = 1;
            });

            write("Sn");

            if(kDebugMode){
              print("[HomeScreen] checking() : patchState $patchState");
            }
          }
          else{
            setState(() {
              patchState = -1;
            });
          }
        }
        break; // Ready

        case 1: {
          if(msgString.contains("Tn")){
            if(kDebugMode){
              print("[HomeScreen] checking() Tn: patchState $patchState");
            }
            String result = msg.last.replaceAll(RegExp(r'[^0-9]'), "");
            battery = double.parse(result);
            if(kDebugMode){
              print("Battery : $battery");
            }
            if(battery >= 4000.0){
              battery = 1.0;
            }else {
              battery -= 3600.0;
              battery /= 400.0;
            }

            if(kDebugMode){
              print("Battery : $battery");
            }

            if(!didInitialSet){
              if(kDebugMode){
                print("[HomeScreen] Checking didInitialSet: $didInitialSet");
              }

              setState(() {
                patchState = 2;
              });

              if (kDebugMode) {
                print("[HomeScreen] Checking set patchState: $patchState");
              }
              // write("Sm0, 100");
              write("status1");
            }
            else{
              if(kDebugMode){
                print("[HomeScreen] Checking didInitialSet: $didInitialSet");
              }

              setState(() {
                patchState = 6;
              });

              // TODO: 일단은 Home에서는 측정 기능만 있고 측정 때만 ble를 사용하기 때문에 그냥 Sj 여기에다 넣었는데 이후에 어떻게될지 모른다
              write("status1");

              if (kDebugMode) {
                print("[HomeScreen] Checking set patchState: $patchState");
              }
            } // if - else: didInitialSet
          } // if: msgString.contains("Tn")

          else{
            setState(() {
              patchState = -1;
            });
          } // else: msgString.contains("Tn")
        }
        break; // Sn

        case 2:
          {
            if(msgString.contains("Return1")){
              setState(() {
                patchState = 3;
              });
              write("Sm0, 100");
            }
            else{
              setState(() {
                patchState = -1;
              });
            }
          }
          break; // status1

        case 3:{
          if(msgString.contains("Tm0")){
            setState(() {
              patchState = 4;
            });
            write("Sl0, 5000");
          }

          else{
            setState(() {
              patchState = -1;
            });
          }
        }
        break; // Sm

        case 4:{
          if(msgString.contains("Tl0")){
            setState(() {
              patchState = 5;
            });
            write("Sk0, 8");
          }

          else{
            setState(() {
              patchState = -1;
            });
          }
        }
        break; // Sl

        case 5: {
          if(msgString.contains("Tk0")){
            setState(() {
              didInitialSet = true;
            });
            write("status0");
          }
          else{
            setState(() {
              patchState = -1;
            });
          }
        }
        break; // Sk

        case 6:{
          if(msgString.contains("Return1")){
            write("Sj");
            setState(() {
              patchState = 7;
            });
          }
          else{
            setState(() {
              patchState = -1;
            });
          }
        }

        case 7:{
          if(msgString.contains("Tj")){
            if(kDebugMode){
              print("[HomeScreen] checking() Tj: patchState $patchState");
            }
            tjmsg.add(msgString);
            if(tjmsg.length % 24 == 0 && tjmsg.isNotEmpty){
              var timeStampForDB = DateFormat("yyyyMMddhhmm").format(DateTime.now());
              ParsingMeasured(timeStampForDB, tjmsg);
              if(kDebugMode){
                print("[HOMESCREEN] PARSING DONE");
              }
              write("status0");
              setState(() {
                patchState = 0;
                measuring = false;
                areYouGoingToWrite = false;
              });
            }
          }
          else{
            setState(() {
              patchState = -1;
            });
          }
        }
        break; // sj

        default: patchState = -1; break;
      }
    }

    if (kDebugMode) {
      int count = 0;
      print("value : $msgString");
      print("------------printing msg---------------");
      for(var element in msg){
        count++;
        print("$count : $element");
      }
      print("heard or listening");
    }
  }

  Future write(String text) async {
    try {
      // TODO : _textCnt.text cmd 확인 절차
      msg.add("[HomeScreen] write(): $text");
      text += "\r";
      // write하기 전에 device를 확인할 필요는 없을 것 같다
      // await device.connectAndUpdateStream();
      // if(kDebugMode){
      //   print("[HomeScreen] write() connectAndUpdateStream then");
      // }
      // init을 할 때 이미 event handler가 듣고 있음 (device 쪽이 listening)

      await device.discoverServices();
      if(kDebugMode){
        print("[HomeScreen] write() discoverServices then");
      }
      await characteristic[idxRx].write(utf8.encode(text), withoutResponse: characteristic[idxRx].properties.writeWithoutResponse);
      if(kDebugMode){
        print("[HomeScreen] write() write characteristic[idxTx] then");
      }

      if (kDebugMode) {
        print("[HomeScreen] wrote: $text");
        print("[HomeScreen] write() _lastValueSubscription paused?: ${_lastValueSubscription.isPaused == true}");
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

  Future reConnect() async{
    if(kDebugMode){
      print("[HomeScreen] reConnect() patch state: $patchState");
    }
    write("St");
    msg.add("Deny Buffer");
    return Future.delayed(const Duration(seconds: 1,));
  }

  Future updateConnection() async{
    await device.connectAndUpdateStream();
    if(patchState == 0){
      reConnect();
    }
  }

  Future updating() async{
    if(_isConnected){
      reConnect();
    }
    else{
      if(kDebugMode){
        print("Device is not connected");
      }
    }
  }

  Future measure() async{
    areYouGoingToWrite = true;
    reConnect().then((value){
      // write("Sj");
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _connectionStateSubscription.cancel();
    _lastValueSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: Text(todayString, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Row(
          children: [
            Container(width: 20,),
            Image.asset("assets/logo.png", width: 80),
          ],
        ),
        leadingWidth: 100,
        actions: [
          InkWell(
            onTap: (){},
            child: Column(
              children: [
                _isConnected? const Icon(Icons.link, size: 30,):const Icon(Icons.link_off, size: 30,),
                _isConnected? const Text("Linked", style: TextStyle(fontWeight: FontWeight.bold),):const Text("Unlinked", style: TextStyle(fontWeight: FontWeight.bold),),
              ],
            ),
          ),
          Container(width: 25,),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: updating,
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(  // 단일 위젯은 요걸로
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, left: 15, right: 15,),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              color: const Color.fromRGBO(178, 212, 182, 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(child: Lottie.asset('assets/lottie/walking.json', frameRate: FrameRate.max, width: 250, height: 230,)),
                                const Padding(
                                  padding: EdgeInsets.only(left: 30.0, right: 30.0, top: 15,),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text("Current", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
                                      Spacer(flex: 1,),
                                      Text("Lv. 3", style: TextStyle(color: Color.fromRGBO(42, 77, 20, 1), fontSize: 20, fontWeight: FontWeight.bold),),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20.0, right: 0.0, top: 5),
                                  child: LinearPercentIndicator(
                                    width: MediaQuery.of(context).size.width * 0.82,
                                    animation: false,
                                    animationDuration: 1000,
                                    lineHeight: 20.0,
                                    percent: 0.375,
                                    center: const Text("Lv. 3", style: TextStyle(fontSize: 13,),),
                                    progressColor: const Color.fromRGBO(42, 77, 20, 1),
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 30.0, right: 30.0, top: 5,),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text("Lv. 0", style: TextStyle(color: Colors.white, fontSize: 17),),
                                      Spacer(flex: 1,),
                                      Text("Lv. 8", style: TextStyle(color: Colors.white, fontSize: 17),),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              height: 22,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 30,),
                                    child: BatteryIndicator(
                                      trackHeight: 17,
                                      value: battery,
                                      iconOutline: Colors.white,
                                    ),
                                  ),
                                  Container(width: 10,),
                                  Text("${(battery*100).round()}%", style: const TextStyle(fontSize: 16,),),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SliverAppBar(
                        backgroundColor: Colors.white,
                        scrolledUnderElevation: 0.0,
                        elevation: 0.0,
                        pinned: true,
                        expandedHeight: MediaQuery.of(context).size.height * 0.12,
                        collapsedHeight: MediaQuery.of(context).size.height * 0.08,
                        automaticallyImplyLeading: false,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(left: 30.0, top: 10.0, right: 0.0, bottom: 25.0),
                          title: RichText(
                            text: const TextSpan(
                              text: "Current Level: 3",
                              style: TextStyle(fontSize: 15, color: Colors.green),
                              children: [
                                TextSpan(
                                  text: "\nFREE",
                                  style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green,
                                  ),
                                ),
                                TextSpan(
                                  text: " to do your activities",
                                  style: TextStyle(
                                    fontSize: 15, color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          centerTitle: false,
                        ),
                      ),

                      SliverToBoxAdapter(  // 단일 위젯은 요걸로
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25),
                          child: SizedBox(
                            height: 70,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                              ),
                              onPressed: (){
                                if(_isConnected){
                                  setState(() {
                                    measuring = true;
                                  });
                                  measure();
                                }
                              },
                              child: const Text("측정", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(  // 단일 위젯은 요걸로
                        child: tjmsg.isEmpty?
                        Container(
                          height: 500.0,
                          color: Colors.red,
                          child: const Center(
                            child: Text("Some Start Widgets"),
                          ),
                        ):
                        SizedBox(
                          height: 500.0,
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tjmsg.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Text(tjmsg[index]);
                            },
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(  // 단일 위젯은 요걸로
                        child: Container(
                          height: 500.0,
                          color: Colors.blueGrey,
                          child: const Center(
                            child: Text("Some Start Widgets"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Offstage(
            offstage: !measuring,
            child: const Stack(
              children: [
                Opacity(
                  opacity: 0.5,
                  child: ModalBarrier(dismissible: false, color: Colors.black,),
                ),
                Center(child: CircularProgressIndicator(),),
              ],
            ),
          ),
        ],
      ),
    );
  }
}