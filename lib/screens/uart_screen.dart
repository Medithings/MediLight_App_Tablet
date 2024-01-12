import 'dart:async';
import 'dart:convert';

import 'package:ble_uart/widgets/message_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../utils/snackbar.dart';

/*
TODO: UART communication
 1. send function (utf8.encode)
  1. cmd 보내기 전 syntax 확인 후 보내기
  2. Tr를 받으면 기기 시스템에서도 삭제
 2. subscribe - init 에서
 3. disconnect 할 때 'Sr\r' 보내고 끝내기
 4. chatting ui ( https://velog.io/@ximya_hf/Flutter-완성도-높은-채팅-기능을-만들기-위한-인터렉션-로직들 )
*/


class UARTScreen extends StatefulWidget {
  const UARTScreen({super.key, required this.service, required this.deviceName});
  static const routeName = '/Uart';

  final BluetoothService service;
  final String deviceName;
  @override
  State<UARTScreen> createState() => _UARTScreenState();
}

class _UARTScreenState extends State<UARTScreen> {
  static const String rx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write data to the rx characteristic to send it to the UART interface.
  static const String tx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Enable notifications for the tx characteristic to receive data from the application.

  final _textCnt = TextEditingController();
  final scrollController = ScrollController();

  final GlobalKey<AnimatedListState> _aniListKey = GlobalKey<AnimatedListState>();

  Widget _buildItem(context, index, animation){
    return MessageTile(msg: msg[index], animation: animation,);
  }

  void _handleSubmitted(String text) {
    Logger().d(text);

    _textCnt.clear();
    msg.insert(0, "${timeStamp()}\t$text write");
    _aniListKey.currentState?.insertItem(0);
    onWritePressed(text);

    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

  }

  int idx_tx = 1;
  int idx_rx = 0;

  List<String> msg = [];

  late StreamSubscription<List<int>> _lastValueSubscription;

  List<BluetoothCharacteristic> get characteristic => widget.service.characteristics;
  // late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    // 중간에 connection 이 해제 되었을 때 snackbar => pop
    // _connectionStateSubscription = widget.device.connectionState.listen((state) async {
    //   if(state != BluetoothConnectionState.connected){
    //     Snackbar.show(ABC.c, "Device has been disconnected", success: false);
    //     Navigator.pop(context);
    //     if(mounted){
    //       setState(() {});
    //     }
    //   }
    // });
    if (kDebugMode) {
      print("switch case start");
    }

    // idx 은 각각의 characteristic 의 index를 표현
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

    // tx channel listen 해서 _lastValueSubscription 에 넣음 + msg 에 decode 해서 add
    _lastValueSubscription = characteristic[idx_tx].lastValueStream.listen((value) {
      String convertedStr = utf8.decode(value).trimRight();
      String formattedStr = "${timeStamp()}\t$convertedStr read";

      if(utf8.decode(value).trim() != ""){
        msg.insert(0, formattedStr);
        _aniListKey.currentState?.insertItem(0);
      }

      if (kDebugMode) {
        int count = 0;
        print("value : $convertedStr");
        print("printing msg");
        for(var element in msg){
          count++;
          print("$count : $element");
        }
        print("heard or listening");
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future onWritePressed(String text) async {
    try {
      // TODO : _textCnt.text cmd 확인 절차
      _textCnt.text += "\r";
      await characteristic[idx_rx].write(utf8.encode(text), withoutResponse: characteristic[idx_rx].properties.writeWithoutResponse);
      // Snackbar.show(ABC.c, "Write: Success", success: true);
      // msg.add("${timeStamp()}:\t${_textCnt.text} write");

      if (kDebugMode) {
        print("wrote: ${timeStamp()}:\t${_textCnt.text}");
      }

      _textCnt.clear();
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
    }
  }

  String timeStamp(){
    DateTime now = DateTime.now();
    String formattedTime = DateFormat.Hms().format(now);
    return formattedTime;
  }

  @override
  void dispose() {
    // _connectionStateSubscription.cancel();
    _lastValueSubscription.cancel();
    characteristic[idx_tx].setNotifyValue(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.deviceName),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedList(
                  shrinkWrap: true,
                  controller: scrollController,
                  key: _aniListKey,
                  reverse: true,
                  itemBuilder: _buildItem,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCnt,
                      decoration: const InputDecoration(hintText: "명령어를 입력하세요"),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _handleSubmitted(_textCnt.text),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30,),
          ],
        ),
      ),
    );
  }
}
