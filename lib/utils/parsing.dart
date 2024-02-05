import 'package:ble_uart/ledmodels/gain_values.dart';
import 'package:ble_uart/utils/database.dart';

void Parsing(String getTimeStamp, List<String> gain) async{
  final _model = DatabaseModel();
  var db = _model.database;

  List<String> splitted;
  String? ledNum;
  double? one;
  double? two;
  double? three;
  double? four;
  double? five;
  double? six;
  double? seven;
  double? eight;
  double? nine;
  double? ten;
  double? eleven;
  double? twelve;

  for(var x in gain){
    splitted = x.split(",");
    ledNum = splitted[0].trim();
    one = double.parse(splitted[1].trim());
    two = double.parse(splitted[2].trim());
    three = double.parse(splitted[3].trim());
    four = double.parse(splitted[4].trim());
    five = double.parse(splitted[5].trim());
    six = double.parse(splitted[6].trim());
    seven = double.parse(splitted[7].trim());
    eight = double.parse(splitted[8].trim());
    nine = double.parse(splitted[9].trim());
    ten = double.parse(splitted[10].trim());
    eleven = double.parse(splitted[11].trim());
    twelve = double.parse(splitted[12].trim());

    await _model.insertingGain(GainValues(
        timeStamp: getTimeStamp,
        lednum: ledNum,
        one: one,
        two: two,
        three: three,
        four: four,
        five: five,
        six: six,
        seven: seven,
        eight: eight,
        nine: nine,
        ten: ten,
        eleven: eleven,
        twelve: twelve
    ));

  }
}