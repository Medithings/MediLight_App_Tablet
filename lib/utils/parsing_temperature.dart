
import 'package:ble_uart/models/temperature_values.dart';
import 'package:ble_uart/utils/database.dart';

void ParsingTemperature(String getETimeStamp, double temperature) async{
  final model = DatabaseModel();
  var db = model.database;

  String? eTimeStamp;
  double? temp;
  temp = temperature;
  eTimeStamp = getETimeStamp;

  print("ParsingTemper: eTimeStamp = $eTimeStamp\ngetTimeStamp = $getETimeStamp");

  await model.insertTemperature(TemperatureValues(
    eTimeStamp: eTimeStamp,
    temperature: temp,
  ));
}