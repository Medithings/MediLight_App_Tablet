import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEInfo extends ChangeNotifier{
  final List<BluetoothDevice>  _device = [];
  final List<BluetoothService> _service = [];

  BluetoothDevice get device => _device.first;
  BluetoothService get service => _service.first;

  set device(BluetoothDevice d) {
    _device.add(d);
    notifyListeners();
  }

  set service(BluetoothService s) {
    _service.add(s);
    notifyListeners();
  }

}