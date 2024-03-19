import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEInfoProvider extends ChangeNotifier{
  final List<BluetoothDevice>  _device = [];
  final List<BluetoothService> _service = [];
  bool _didPassBetween = false;

  BluetoothDevice get device => _device.first;
  BluetoothService get service => _service.first;
  bool get didPassBetween => _didPassBetween;

  set device(BluetoothDevice d) {
    _device.add(d);
    notifyListeners();
  }

  set service(BluetoothService s) {
    _service.add(s);
    notifyListeners();
  }

  set didPassBetween(bool x){
    _didPassBetween = x;
    notifyListeners();
  }

}