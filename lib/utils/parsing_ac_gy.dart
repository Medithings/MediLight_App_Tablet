import 'package:ble_uart/models/ac_gy_vlaues.dart';
import 'package:ble_uart/utils/database.dart';

void ParsingAcGy(String getETimeStamp, String acgy) async{
  final model = DatabaseModel();
  var db = model.database;

  List<String> splitting;
  String? eTimeStamp;
  int? accX;
  int? accY;
  int? accZ;
  int? gyrX;
  int? gyrY;
  int? gyrZ;

  splitting = acgy.split(",");
  eTimeStamp = getETimeStamp;
  accX = int.parse(splitting[0].trim());
  accY = int.parse(splitting[1].trim());
  accZ = int.parse(splitting[2].trim());

  gyrX = int.parse(splitting[3].trim());
  gyrY = int.parse(splitting[4].trim());
  gyrZ = int.parse(splitting[5].trim());

  print("ParsingAcGy: getETimeStamp = $getETimeStamp\neTimeStamp = $eTimeStamp");

  await model.insertingACGY(ACGY(
    eTimeStamp: eTimeStamp,
    accX: accX,
    accY: accY,
    accZ: accZ,
    gyrX: gyrX,
    gyrY: gyrY,
    gyrZ: gyrZ,
  ));
}