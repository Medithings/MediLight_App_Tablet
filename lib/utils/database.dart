import 'dart:async';

import 'package:ble_uart/models/agc_values.dart';
import 'package:ble_uart/models/measured_time.dart';
import 'package:ble_uart/models/measured_values.dart';
import 'package:ble_uart/models/temperature_values.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/ac_gy_vlaues.dart';

class DatabaseModel{
  Database? _database;

  Future<Database> get database async{
    if(_database != null) {
      print("[DB] has database");
      return _database!;
    }

    print("[DB] openning DB");
    return await initDB();
  }

  initDB() async{
    print("[DB] init DB");
    String path = p.join(await getDatabasesPath(), 'mediLight.db');

    if(kDebugMode){
      print("[DatabaseModel] path: $path");
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      readOnly: false,
    );
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) {}

  FutureOr<void> _onCreate(Database db, int version){
    print("[DB] onCreate DB");

    db.execute('''
    CREATE TABLE agc_values(
      timeStamp TEXT,
      LEDNUM TEXT,
      led1 REAL,
      led2 REAL,
      led3 REAL,
      led4 REAL,
      led5 REAL,
      led6 REAL,
      led7 REAL,
      led8 REAL,
      led9 REAL,
      led10 REAL,
      led11 REAL,
      led12 REAL,
      led13 REAL,
      led14 REAL,
      led15 REAL,
      led16 REAL,
      led17 REAL,
      led18 REAL,
      led19 REAL,
      led20 REAL,
      led21 REAL,
      led22 REAL,
      led23 REAL,
      led24 REAL,
      led25 REAL,
      PRIMARY KEY(timeStamp, LEDNUM)
      );
    ''');
    // TODO: indexing LEDNUM

    db.execute(''' 
    CREATE TABLE measured_values(
      mTimeStamp TEXT,
      LEDNUM TEXT,
      one REAL,
      two REAL,
      three REAL,
      four REAL,
      five REAL,
      six REAL,
      seven REAL,
      eight REAL,
      nine REAL,
      ten REAL,
      eleven REAL,
      twelve REAL,
      PRIMARY KEY(mTimeStamp, LEDNUM)
      );
    ''');
    // TODO: indexing LEDNUM

    db.execute('''
    CREATE TABLE etc(
      eTimeStamp TEXT,
      acc_x INTEGER,
      acc_y INTEGER,
      acc_z INTEGER,
      gyr_x INTEGER,
      gyr_y INTEGER,
      gyr_z INTEGER,
      temper REAL,
      mTimeStamp TEXT
      );
    ''');

    db.execute('''
    CREATE TABLE led_pd(
      LEDNUM TEXT,
      one INTEGER,
      two INTEGER,
      three INTEGER,
      four INTEGER,
      five INTEGER,
      six INTEGER,
      seven INTEGER,
      eight INTEGER,
      nine INTEGER,
      ten INTEGER,
      eleven INTEGER,
      twelve INTEGER,
      PRIMARY KEY(LEDNUM)
      );
    ''');

    LED_PD ledPdInfo = LED_PD();

    for(int i=0; i<4; i++) {
      db.insert(
          'led_pd',
          {'LEDNUM': ledPdInfo.lednum[i],
            'one': ledPdInfo.one[i],
            'two': ledPdInfo.two[i],
            'three': ledPdInfo.three[i],
            'four': ledPdInfo.four[i],
            'five': ledPdInfo.five[i],
            'six': ledPdInfo.six[i],
            'seven': ledPdInfo.seven[i],
            'eight': ledPdInfo.eight[i],
            'nine': ledPdInfo.nine[i],
            'ten': ledPdInfo.ten[i],
            'eleven': ledPdInfo.eleven[i],
            'twelve': ledPdInfo.twelve[i],
          }
      );
    }
  }

  Future<void> insertingMeasured(MeasuredValues item) async{
    var db = await database;

    await db.insert(
        'measured_values',
        item.toMap()
    );
  }

  Future<void> insertingAGC(AgcValues item) async{
    var db = await database;

    await db.insert(
        'agc_values',
        item.toMap()
    );
  }

  Future<void> insertTemperature(TemperatureValues item) async{
    var db = await database;

    await db.rawInsert(
      "INSERT INTO etc(eTimeStamp, temper) VALUES(${item.eTimeStamp}, ${item.temperature})"
    );
  }

  Future<void> insertingACGY(ACGY item) async{
    var db = await database;

    print("inserintACGY: item.eTimeStamp = ${item.eTimeStamp}");
    await db.rawUpdate(
      "UPDATE etc SET eTimestamp = ?, acc_x = ?, acc_y = ?, acc_z = ?, gyr_x = ?, gyr_y = ?, gyr_z = ? WHERE eTimeStamp = ?",
      ['${item.eTimeStamp}, ${item.accX}, ${item.accY}, ${item.accZ}, ${item.gyrX}, ${item.gyrY}, ${item.gyrZ}, ${item.eTimeStamp}']
    );
    await db.update(
      "etc",
      {
        "eTimeStamp" : "${item.eTimeStamp}",
        "acc_x" : "${item.accX}",
        "acc_y" : "${item.accY}",
        "acc_z" : "${item.accZ}",
      },
    );
  }

  Future<List<MeasuredTime>> timeStampGroupBy() async {
    var db = await database;

    // testTable 테이블에 있는 모든 field 값을 maps에 저장한다.
    final List<Map<String, dynamic>> maps = await db.rawQuery("SELECT mTimeStamp FROM measured_values GROUP BY mTimeStamp ORDER BY mTimeStamp DESC");

    return List.generate(maps.length, (index) {
      return MeasuredTime(
        timeStamp: maps[index]['mTimeStamp'] as String,
      );
    });
  }
}

class LED_PD {
  final List<String> lednum = ['Tj1-6', 'Tj7-12', 'Tj13-18', 'Tj19-24'];
  final List<String> one = ['pd5', 'pd6', 'pd15', 'pd16'];
  final List<String> two = ['pd6', 'pd5', 'pd16', 'pd15'];
  final List<String> three = ['pd7', 'pd4', 'pd17', 'pd14'];
  final List<String> four = ['pd8', 'pd3', 'pd18', 'pd13'];
  final List<String> five = ['pd9', 'pd2', 'pd19', 'pd12'];
  final List<String> six = ['pd10', 'pd1', 'pd20', 'pd11'];
  final List<String> seven = ['pd15', 'pd16', 'pd5', 'pd6'];
  final List<String> eight = ['pd16', 'pd15', 'pd6', 'pd5'];
  final List<String> nine = ['pd17', 'pd14', 'pd7', 'pd4'];
  final List<String> ten = ['pd18', 'pd13', 'pd8', 'pd3'];
  final List<String> eleven = ['pd19', 'pd12', 'pd9', 'pd2'];
  final List<String> twelve = ['pd20', 'pd11', 'pd10', 'pd1'];
}

