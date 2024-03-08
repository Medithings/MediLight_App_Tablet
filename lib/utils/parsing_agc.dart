import 'package:ble_uart/models/agc_values.dart';
import 'package:ble_uart/utils/database.dart';

void ParsingAGC(String getTimeStamp, List<String> gain) async{
  final model = DatabaseModel();
  model.database;

  List<String> splitted;
  String? ledNum;
  int? led1;
  int? led2;
  int? led3;
  int? led4;
  int? led5;
  int? led6;
  int? led7;
  int? led8;
  int? led9;
  int? led10;
  int? led11;
  int? led12;
  int? led13;
  int? led14;
  int? led15;
  int? led16;
  int? led17;
  int? led18;
  int? led19;
  int? led20;
  int? led21;
  int? led22;
  int? led23;
  int? led24;
  int? led25;

  for(var x in gain){
    splitted = x.split(",");
    ledNum = splitted[0].trim();
    led1 = int.parse(splitted[1].trim());
    led2 = int.parse(splitted[2].trim());
    led3 = int.parse(splitted[3].trim());
    led4 = int.parse(splitted[4].trim());
    led5 = int.parse(splitted[5].trim());
    led6 = int.parse(splitted[6].trim());
    led7 = int.parse(splitted[7].trim());
    led8 = int.parse(splitted[8].trim());
    led9 = int.parse(splitted[9].trim());
    led10 = int.parse(splitted[10].trim());
    led11 = int.parse(splitted[11].trim());
    led12 = int.parse(splitted[12].trim());
    led13 = int.parse(splitted[13].trim());
    led14 = int.parse(splitted[14].trim());
    led15 = int.parse(splitted[15].trim());
    led16 = int.parse(splitted[16].trim());
    led17 = int.parse(splitted[17].trim());
    led18 = int.parse(splitted[18].trim());
    led19 = int.parse(splitted[19].trim());
    led20 = int.parse(splitted[20].trim());
    led21 = int.parse(splitted[21].trim());
    led22 = int.parse(splitted[22].trim());
    led23 = int.parse(splitted[23].trim());
    led24 = int.parse(splitted[24].trim());
    led25 = int.parse(splitted[25].trim());

    await model.insertingAGC(AgcValues(
      timeStamp: getTimeStamp,
      lednum: ledNum,
      led1: led1,
      led2: led2,
      led3: led3,
      led4: led4,
      led5: led5,
      led6: led6,
      led7: led7,
      led8: led8,
      led9: led9,
      led10: led10,
      led11: led11,
      led12: led12,
      led13: led13,
      led14: led14,
      led15: led15,
      led16: led16,
      led17: led17,
      led18: led18,
      led19: led19,
      led20: led20,
      led21: led21,
      led22: led22,
      led23: led23,
      led24: led24,
      led25: led25,
    ));

  }
}