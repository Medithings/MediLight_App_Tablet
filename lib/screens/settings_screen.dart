import 'package:ble_uart/screens/alarm_set_screen.dart';
import 'package:ble_uart/widgets/settings_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences pref;
  String name = "";

  @override
  void initState() {
    prefGetter();
    // TODO: implement initState
    super.initState();
  }

  void prefGetter() async {
    pref = await SharedPreferences.getInstance();

    try{
      setState(() {
        name = pref.getString("name")!;
      });
    }catch(e){
      if (kDebugMode) {
        print("error : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Align(alignment: Alignment.centerLeft, child: Text("Settings")),
            floating: true,
            // flexibleSpace: Placeholder(),
            expandedHeight: 200,
          ),
          const SliverToBoxAdapter(
            child: Text('Account', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),),
          ),
          SliverToBoxAdapter(
            child: SettingsTile(stIcon: Icons.person, title: name, goto: const AccountScreen(),),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20,),
          ),
          const SliverToBoxAdapter(
            child: Text('Settings', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),),
          ),
          SliverToBoxAdapter(
            child: SettingsTile(stIcon: Icons.notifications_rounded, title: "Alarm", goto: const AlarmSetScreen(),),
          ),
          SliverToBoxAdapter(
            child: SettingsTile(stIcon: Icons.notifications_rounded, title: "Alarm", goto: const AlarmSetScreen(),),
          ),
        ],
      ),
    );
  }
}
