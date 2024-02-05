import 'dart:async';

import 'package:ble_uart/ledmodels/gain_values.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../ledmodels/led_pd.dart';

class DatabaseModel{
  Database? _database;

  Future<Database> get database async{
    if(_database != null) return _database!;
    return await initDB();
  }

  initDB() async{
    String path = p.join(await getDatabasesPath(), 'gain_database.db');

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
    String sql = '''
    CREATE TABLE Gain_values(
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
    CREATE TABLE LED_PD(
      LEDNUM TEXT PRIMARY KEY,
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
    ''';
    db.execute(sql);
  }

  Future<void> insertingGain(GainValues item) async{
    var db = await database;

    await db.insert(
      'Gain_values',
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

