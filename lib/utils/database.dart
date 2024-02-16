import 'dart:async';

import 'package:ble_uart/ledmodels/agc_values.dart';
import 'package:ble_uart/ledmodels/measured_values.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseModel{
  Database? _database;

  Future<Database> get database async{
    if(_database != null) return _database!;
    return await initDB();
  }

  initDB() async{
    String path = p.join(await getDatabasesPath(), 'mediLight.db');

    if(kDebugMode){
      print("[DatabaseModel] path: $path");
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) {}

  FutureOr<void> _onCreate(Database db, int version){
    String sqlAgctable = '''
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
    ''';
    // TODO: indexing LEDNUM
    db.execute(sqlAgctable);

    String sqlMeasuredtable=''' 
    CREATE TABLE measured_values(
      timeStamp TEXT,
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
      PRIMARY KEY(timeStamp, LEDNUM)
      );
    ''';
    // TODO: indexing LEDNUM
    db.execute(sqlMeasuredtable);

    String sqlLedPd = '''
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
    ''';
    db.execute(sqlLedPd);
    LED_PD ledPdInfo = LED_PD();
    insertingLedPd(ledPdInfo);
  }

  Future<void> insertingMeasured(MeasuredValues item) async{
    var db = await database;

    await db.insert(
        'measured_values',
        item.toMap()
    );
  }

  Future<void>insertingAGC(AgcValues item) async{
    var db = await database;

    await db.insert(
        'agc_values',
        item.toMap()
    );
  }

  Future<void> insertingLedPd(LED_PD item) async{
    var db = await database;

    for(int i=0; i<4; i++){
      await db.insert(
          'LED_PD',
          {'LEDNUM' : item.lednum[i],
            'one' : item.one[i],
            'two' : item.two[i],
            'three' : item.three[i],
            'four' : item.four[i],
            'five' : item.five[i],
            'six' : item.six[i],
            'seven' : item.seven[i],
            'eight' : item.eight[i],
            'nine' : item.nine[i],
            'ten' : item.ten[i],
            'eleven' : item.eleven[i],
            'twelve' : item.twelve[i],
          }
      );
    }


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
