import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTile extends StatelessWidget {
  SettingsTile({super.key, required this.stIcon, required this.title, required this.goto});


  IconData stIcon;
  String title;
  Widget goto;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return InkWell(
      onTap: () => navigator.push(CupertinoPageRoute(builder: (context) => goto,),),
      child: Row(
        children: [
          Icon(stIcon),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold),),
        ],
      ),
    );
  }
}
