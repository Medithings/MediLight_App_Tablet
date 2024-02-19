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
import 'package:rive/rive.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
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

  late int level;
  late int maxLevel;
  late int levelIdx;
  late double riveIdx;
  late StateMachineController _stmController;
  SMIInput<double>? _numberExampleInput;
  ValueNotifier<double> batteryValue = ValueNotifier(0);

  List<String> cmtTitle = ["\nFREE", "\nPREPARE", "\n!!WARNING!!"];
  List<Color> cmtColors = [Colors.green, Colors.orange, Colors.red];
  List<Color> cardColors = [const Color.fromRGBO(200,225,204, 1), const Color.fromRGBO(255,215,105, 1), const Color.fromRGBO(253,216,216,1)];
  List<Color> infoColors = [const Color.fromRGBO(143,182,171, 1), const Color.fromRGBO(231,159,49, 1), const Color.fromRGBO(238,114,114,1)];
  List<Color> batteryColors = [const Color.fromRGBO(200,225,204, 1), const Color.fromRGBO(255,215,105, 1), const Color.fromRGBO(253,216,216,1)];

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

    level = 3;
    maxLevel = 8;
    levelIdx = 0;
    batteryValue.value = 0;
    riveIdx = -1;

    if(_connectionState == BluetoothConnectionState.disconnected){
      if(kDebugMode){
        print("[HomeScreen] The device is disconnected");
      }
      device.connectAndUpdateStream();
    }
    // msg.add("START!");

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

      if(kDebugMode){
        print("[HomeScreen] initState() state: $state");
      }

      if(state == BluetoothConnectionState.disconnected){
        setState(() {
          patchState = 0;
          battery = 0.0;
          batteryValue.value = 0;
          didInitialSet = false;
          level = -1;
          _numberExampleInput?.value = -1.0;
        });
        updatingLevelIdx();
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
        updatingLevelIdx();
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
              batteryValue.value = battery * 100;
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
            setState(() {
              patchState = 7;
            });
            if(areYouGoingToWrite) {
              write("Sj");
            } else {
              write("status0");
            }
          }
          else{
            setState(() {
              patchState = -1;
            });
          }
        }
        break;

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
          else if(msgString.contains("Return0")){
            setState(() {
              patchState = 0;
            });
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
    setState(() {
      areYouGoingToWrite = true;
    });
    reConnect().then((value){
      // write("Sj");
    });
  }

  void _riveOneInit(Artboard art){
    _stmController = StateMachineController.fromArtboard(art, 'State Machine 1') as StateMachineController;
    _stmController.isActive = true;
    art.addController(_stmController);
    _numberExampleInput = _stmController.findInput<double>('Number 1') as SMINumber;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp){
      setState(() {
        _numberExampleInput?.value = riveIdx;
      });
    });
  }

  List<TextStyle> cmtTitleStyle = [
    const TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green,
    ),
    const TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange,
    ),
    const TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red,
    ),
  ];

  List<String> cmt = [" to do your activities", " for your urination", "  do your catheterization",];
  TextStyle cmtStyle = const TextStyle(fontSize: 15, color: Colors.black,);

  void updatingLevelIdx(){
    if(_isConnected){
      if(level < maxLevel/2){
        setState(() {
          levelIdx = 0;
          riveIdx = levelIdx.toDouble();
          _numberExampleInput?.value = riveIdx;
        });
      }
      else if(level == maxLevel/2){
        setState(() {
          levelIdx = 1;
          riveIdx = levelIdx.toDouble();
          _numberExampleInput?.value = riveIdx;
        });
      }
      else if(level == -1){
        setState(() {
          levelIdx = 0;
          riveIdx = -1;
          _numberExampleInput?.value = riveIdx;
        });
      }
      else{
        setState(() {
          levelIdx = 2;
          riveIdx = levelIdx.toDouble();
          _numberExampleInput?.value = riveIdx;
        });
      }
    }
  }

  TextSpan checkingCmt(){
    if(level < maxLevel/2){
      return TextSpan(
        text: cmtTitle[0],
        style: cmtTitleStyle[0],
      );
    }
    else if(level == maxLevel/2){
      return TextSpan(
        text: cmtTitle[1],
        style: cmtTitleStyle[1],
      );
    }
    else{
      return TextSpan(
        text: cmtTitle[2],
        style: cmtTitleStyle[2],
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _connectionStateSubscription.cancel();
    _lastValueSubscription.cancel();
    _stmController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        elevation: 0.0,
        toolbarHeight: 100,
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
              mainAxisAlignment: MainAxisAlignment.center,
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
                          padding: const EdgeInsets.only(left: 15, right: 15,),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.44,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                              color: cardColors[levelIdx],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20,),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40, right: 40),
                                  child: Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: _isConnected? Colors.black:Colors.redAccent,
                                      borderRadius: const BorderRadius.all(Radius.circular(70)),
                                    ),

                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Spacer(flex: 1,),
                                        // BatteryIndicator(
                                        //   trackHeight: 17,
                                        //   value: 0.9,
                                        //   iconOutline: Colors.white,
                                        // ),
                                        _isConnected? const Icon(Icons.bolt_rounded, color: Colors.greenAccent, size: 30,) : const Icon(Icons.cancel, color: Colors.black, size: 30,),
                                        const SizedBox(width: 10,),
                                        _isConnected? const Text("MediLight", style: TextStyle(fontSize: 20, color: Colors.white),) :const Text("No Connection", style: TextStyle(fontSize: 20, color: Colors.white),),
                                        _isConnected? const Spacer(flex: 2,) : const SizedBox(),
                                        _isConnected?
                                          SizedBox(
                                            width: 53,
                                            height: 53,
                                            child: SimpleCircularProgressBar(
                                              valueNotifier: batteryValue,
                                              progressStrokeWidth: 3,
                                              backStrokeWidth: 3,
                                              mergeMode: true,
                                              animationDuration: 0,
                                              onGetText: (double value){
                                                return Text("${value.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 20,),);
                                              },
                                            ),
                                          ):
                                          const SizedBox(),
                                        const Spacer(flex: 1,),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40,),
                                // Center(child: Lottie.asset('assets/walking.json', frameRate: FrameRate.max, width: 250, height: 230,)),
                                SizedBox(
                                  // color: Colors.purpleAccent,
                                  height: 180,
                                  width: MediaQuery.of(context).size.height * 0.23,
                                  child: RiveAnimation.asset(
                                    "assets/rive/lil_guy_updated.riv",
                                    fit: BoxFit.fill,
                                    onInit: _riveOneInit,
                                    alignment: Alignment.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(  // 단일 위젯은 요걸로
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15,),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.15,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                              color: infoColors[levelIdx],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 15,),
                                // Center(child: Lottie.asset('assets/walking.json', frameRate: FrameRate.max, width: 250, height: 230,)),
                                Padding(
                                  padding: const EdgeInsets.only(left: 30.0, right: 30.0,),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text("Current", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
                                      const Spacer(flex: 1,),
                                      Text("Lv. $level", style: const TextStyle(color: Color.fromRGBO(42, 77, 20, 1), fontSize: 20, fontWeight: FontWeight.bold),),
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
                                    percent: level >= 0? level/maxLevel : 0/maxLevel,
                                    center: Text("Lv. $level", style: const TextStyle(fontSize: 15,),),
                                    progressColor: const Color.fromRGBO(42, 77, 20, 1),
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 5,),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text("Lv. $level", style: const TextStyle(color: Colors.white, fontSize: 17),),
                                      const Spacer(flex: 1,),
                                      Text("Lv. $maxLevel", style: const TextStyle(color: Colors.white, fontSize: 17),),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 15,
                        ),
                      ),

                      SliverAppBar(
                        scrolledUnderElevation: 0.0,
                        pinned: true,
                        expandedHeight: MediaQuery.of(context).size.height * 0.13,
                        collapsedHeight: MediaQuery.of(context).size.height * 0.1,
                        backgroundColor: Colors.white,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(left: 30.0, top: 5.0, right: 0.0, bottom: 15.0),
                          title: RichText(
                            text: TextSpan(
                              text: "Current Level: $level",
                              style: TextStyle(fontSize: 15, color: cmtColors[levelIdx]),
                              children: [
                                checkingCmt(),
                                level < maxLevel/2?
                                TextSpan(
                                  text: cmt[0],
                                  style: cmtStyle,
                                ) :
                                level == maxLevel/2?
                                TextSpan(
                                  text: cmt[1],
                                  style: cmtStyle,
                                ) :
                                TextSpan(
                                  text: cmt[2],
                                  style: cmtStyle,
                                ),
                              ],
                            ),
                          ),
                          centerTitle: false,
                        ),
                      ),

                      SliverToBoxAdapter(  // 단일 위젯은 요걸로
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
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
                        child: SizedBox(
                          height: 130.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(147, 192, 164, 1),
                                ),
                                onPressed: (){
                                  setState(() {
                                    level = 3;
                                    updatingLevelIdx();
                                  });
                                },
                                child: const Text("Lv 3", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                              ),

                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(182, 196, 162, 1),
                                ),
                                onPressed: (){
                                  setState(() {
                                    level = 4;
                                    updatingLevelIdx();
                                  });
                                },
                                child: const Text("Lv 4", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                              ),

                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(212, 205, 171, 1),
                                ),
                                onPressed: (){
                                  setState(() {
                                    level = 5;
                                    updatingLevelIdx();
                                  });
                                },
                                child: const Text("Lv 5", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                              ),
                            ],
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
