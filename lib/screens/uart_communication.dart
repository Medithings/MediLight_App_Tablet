import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class UARTCommunication extends StatefulWidget {
  const UARTCommunication({super.key, required this.device});
  final BluetoothDevice device;

  @override
  State<UARTCommunication> createState() => _UARTCommunicationState();
}

class _UARTCommunicationState extends State<UARTCommunication> {
  List<String> _mesg = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UART Communication'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          ListView.builder(
            itemBuilder: (BuildContext context, int index){

            },
          )
        ],
      ),
    );
  }
}
