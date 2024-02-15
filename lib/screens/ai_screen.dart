import 'dart:async';
import 'dart:convert';

import 'package:ble_uart/screens/between_screen.dart';
import 'package:ble_uart/screens/bottom_navigation_screen.dart';
import 'package:ble_uart/utils/extra.dart';
import 'package:ble_uart/utils/parsing_agc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../utils/ble_info.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {

  static const String rx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write data to the rx characteristic to send it to the UART interface.
  static const String tx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Enable notifications for the tx characteristic to receive data from the application.

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<List<int>> _lastValueSubscription;

  late BluetoothDevice device;
  late BluetoothService service;
  late List<BluetoothCharacteristic> characteristic;

  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  bool _isConnected = false;
  int? _rssi;

  int idxTx = 1;
  int idxRx = 0;

  List<String> msg = [];
  List<String> agcMsg = [];

  int patchState = 0;
  double battery = 0.0;

  String todayString = "";

  bool measuring = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero, (){
      if(kDebugMode){
        print("[AIScreen] !!Init state start!!");
        print("[AIScreen] patch state is $patchState");
      }

      todayString = DateFormat.yMMMd().format(DateTime.now());

      device = context.read<BLEInfo>().device;
      service = context.read<BLEInfo>().service;
      characteristic = service.characteristics;

      // device.connectAndUpdateStream();
      connecting();

      msg.clear();
      // msg.add("START!");

      _connectionStateSubscription = device.connectionState.listen((state) async {
        _connectionState = state;

        if(kDebugMode){
          print("[HomeScreen] initState() state: $state");
        }

        if(state == BluetoothConnectionState.disconnected){
          // TODO: 블루투스 연결이 해제 되었으니 dispose하고 연결이 해제되었다고 알림 => 연결 페이지로 넘어가시겠습니까? => Navigate to ScanScreen
          // TODO: ALERT & Navigate
          // noConnection();

          // setState(() {
          //   patchState = -1;
          //   battery = 0.0;
          // });
          // device.connectAndUpdateStream();
          // _lastValueSubscription.pause();
          // if(kDebugMode){
          //   print("[HomeScreen] patchState = $patchState");
          //   print("[HomeScreen] _lastValueSubscription paused?: ${_lastValueSubscription.isPaused == true}");
          // }
        }
        if(state == BluetoothConnectionState.connected){
          if(kDebugMode){
            print("-------[HomeScreen] _connectionState listeningToChar()-------");
          }
          listeningToChar();
          write("St");
          if(kDebugMode){
            print("-------[HomeScreen] _connectionState listeningToChar() done-------");
          }
          if(kDebugMode){
            print("[AIScreen] _lastValueSubscription paused?: ${_lastValueSubscription.isPaused == true}");
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
    });
  }

  // @override
  // void didChangeDependencies(){
  //   super.didChangeDependencies();
  //
  //
  // }

  void connecting() async{
    await device.connectAndUpdateStream();
  }

  void listeningToChar(){
    service = context.read<BLEInfo>().service;

    if(kDebugMode){
      print("[AIScreen] listeningToChar(): service uid is ${service.uuid.toString().toUpperCase()}");
    }
    characteristic = service.characteristics;
    if(kDebugMode){
      print("[AIScreen] listeningToChar(): first element of char is ${characteristic[0].uuid.toString().toUpperCase()}");
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
      print("[AIScreen] listeningToChar(): Before set notify value discover services");
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

  @override
  void dispose() {
    // TODO: implement dispose
    _connectionStateSubscription.cancel();
    _lastValueSubscription.cancel();
    super.dispose();
  }

  void checking(String msgString){
    if(kDebugMode){
      print("-------[AIScreen] checking start-------");
      print("[AIScreen] checking() current patch state: $patchState");
    }

    if(msgString != ""){
      msg.add(msgString);

      if(msgString.contains("Ready")){
        setState(() {
          patchState = 1;
        });

        write("Sn");

        if(kDebugMode){
          print("[AIScreen] checking() : patchState $patchState");
        }
      }

      if(patchState == 1 && msgString.contains("Tn")){
        if(kDebugMode){
          print("[AIScreen] checking() Tn: patchState $patchState");
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

        setState(() {
          patchState = 2;
          if(kDebugMode){
            print("[AIScreen] checking()-Tn: patch state should be 0: $patchState");
          }
        });

        write("status1");
      }
      
      if(patchState == 2 && msgString.contains("Return1")){
        write("Sm0, 100");
        setState(() {
          patchState = 3;
        });
      }

      if(patchState == 3 && msgString.contains("Tm0")){
        write("Sl0, 5000");
        setState(() {
          patchState = 4;
        });
      }
      // TODO: error처리 (else)

      if(patchState == 4 && msgString.contains("Tl0")){
        write("Sk0, 8");
        setState(() {
          patchState = 0;
        });
      }

      if(patchState == 0 && msgString.contains("Tagc")){
        // TODO: add in agc values
        agcMsg.add(msgString);
        if(agcMsg.length % 42 == 0 && agcMsg.isNotEmpty){
          var timeStampForDB = DateFormat("yyyyMMddhhmm").format(DateTime.now());
          ParsingAGC(timeStampForDB, agcMsg);
          if(kDebugMode){
            print("[AIScreen] PARSING DONE");
          }
          write("status0");
        }
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
      msg.add("[AIScreen] write(): $text");
      text += "\r";
      // write하기 전에 device를 확인할 필요는 없을 것 같다
      // await device.connectAndUpdateStream();
      // if(kDebugMode){
      //   print("[AIScreen] write() connectAndUpdateStream then");
      // }
      // init을 할 때 이미 event handler가 듣고 있음 (device 쪽이 listening)

      await device.discoverServices();
      if(kDebugMode){
        print("[AIScreen] write() discoverServices then");
      }
      await characteristic[idxRx].write(utf8.encode(text), withoutResponse: characteristic[idxRx].properties.writeWithoutResponse);
      if(kDebugMode){
        print("[AIScreen] write() write characteristic[idxTx] then");
      }

      if (kDebugMode) {
        print("[AIScreen] wrote: $text");
        print("[AIScreen] write() _lastValueSubscription paused?: ${_lastValueSubscription.isPaused == true}");
      }
    } catch (e) {
      if(kDebugMode){
        print("[AIScreen] wrote error\nError: $e");
      }
    }
  }

  List<String> measureLog = [];
  final txtController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String timeStamp(){
    DateTime now = DateTime.now();
    String formattedTime = DateFormat.Hms().format(now);
    return formattedTime;
  }

  void _confirm(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("Confirming input data"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("측정 용량: ${txtController.text} ml"),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: (){
                  setState(() {
                    String log = "";
                    log += timeStamp();
                    log += ":  ${txtController.text} ml";
                    measureLog.add(log);
                    txtController.clear();
                    Navigator.of(context).pop();
                  });
                },
                child: const Text("측정"),
              ),
            ],
          );
        }
    );
  }

  void _zeroConfirm(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("Zero confirm?"),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("측정 용량: 0 ml"),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: (){
                  setState(() {
                    String log = "";
                    log += timeStamp();
                    log += ":  0 ml";
                    measureLog.add(log);
                    txtController.clear();
                    Navigator.of(context).pop();
                  });
                },
                child: const Text("측정"),
              ),
            ],
          );
        }
    );
  }

  void trainConfirm(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("학습을 시작하시겠습니까?"),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("확인을 누르면 학습 페이지로 넘어갑니다"),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: (){
                  late Route route = MaterialPageRoute(builder: (context) => const BottomNavigationScreen());
                  Navigator.of(context).popUntil((rr) => rr.isFirst);
                  Navigator.pushReplacement(context, route);
                },
                child: const Text("확인"),
              ),
            ],
          );
        }
    );
  }

  void noConnection(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("패치와 연결이 해제되었습니다"),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("확인을 누르면 연결 페이지로 넘어갑니다"),
              ],
            ),
            actions: [
              // ElevatedButton(
              //   onPressed: () => Navigator.of(context).pop(),
              //   child: const Text("취소"),
              // ),
              ElevatedButton(
                onPressed: (){
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const BetweenScreen()),
                  );
                },
                child: const Text("확인"),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_scrollController.hasClients){
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 10,),
            curve: Curves.linear);
      }
    });

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Row(
            children: [
              SizedBox(width: 20,),
              Text("인공지능 학습", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25,),),
            ],
          ),
          elevation: 0.0,
          scrolledUnderElevation: 0.0,
          backgroundColor: Colors.white,
          centerTitle: false,
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
        ),

        body: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ListView(
              // mainAxisAlignment: MainAxisAlignment.end,
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black12,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 20, top: 20,),
                    child: Text(
                      "안내사항\n의료진의 안내에 따라주세요.",
                      style: TextStyle(color: Colors.black54, fontSize: 17, ),
                    ),
                  ),
                ),
                // const Spacer(flex: 8,),
                const Divider(thickness: 2.0, height: 75,),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 80,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(126, 189, 194, 1),
                    ),
                    onPressed: (){
                      write("status1");
                      Future.delayed(const Duration(seconds: 1), (){
                        write("agc");
                      });
                    },
                    child: const Text("기기최적화", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                  ),
                ),

                const SizedBox(height: 30,),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 80,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(126, 189, 194, 1),
                    ),
                    onPressed: _zeroConfirm,
                    child: const Text("0ml   측정", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                  ),
                ),
                const SizedBox(height: 30,),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10,),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: txtController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '측정 용량을 적어주세요',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(35, 31, 32, 1),
                        ),
                        onPressed: _confirm,
                        child: const Text("확인", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10,),

                const Divider(thickness: 2.0, height: 80,),

                const Padding(
                  padding: EdgeInsets.only(left: 10, bottom: 20,),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Icon(Icons.book),
                        SizedBox(width: 10,),
                        Text("학습 로그", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25,),),
                      ],
                    ),
                  ),
                ),

                measureLog.isNotEmpty ?
                Padding(
                  padding: const EdgeInsets.only(left: 10,),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black12,
                    ),
                    height: 200,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 25, top: 25),
                        child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: measureLog.length,
                            reverse: true,
                            itemBuilder: (context, index){
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    measureLog[index],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 15,),
                                ],
                              );
                            }
                        ),
                      ),
                    ),
                  ),
                ): Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black12,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 20, top: 20,),
                      child: Text("아직 측정된 데이터가 없습니다", style: TextStyle(fontSize: 17, color: Colors.black54,),),
                    ),
                  ),
                ),
                // const Spacer(flex: 1,),

                measureLog.length >= 2 ?
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 20,),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 70,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                      ),
                      onPressed: trainConfirm,
                      child: const Text("학습 시작", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                    ),
                  ),
                ): Container(),

                const SizedBox(height: 50,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
