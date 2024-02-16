import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTile extends StatelessWidget {
  SettingsTile({super.key, required this.stIcon, required this.title, required this.goto, required this.bgColor});

  IconData stIcon;
  String title;
  Widget goto;
  Color bgColor;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return InkWell(
      onTap: () => navigator.push(CupertinoPageRoute(builder: (context) => goto,),),
      child: Row(
        children: [
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent),
                  color: bgColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
                child: Icon(stIcon, color: Colors.white, size: 20,),
              ),
            ),
          ),
          const SizedBox(width: 15,),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold),),
        ],
      ),
    );
  }
}
