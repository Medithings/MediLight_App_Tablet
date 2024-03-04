import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.stIcon, required this.title, required this.goto, required this.bgColor});

  final IconData stIcon;
  final String title;
  final Widget goto;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return SizedBox(
      height: 50,
      child: InkWell(
        onTap: () => navigator.push(CupertinoPageRoute(builder: (context) => goto,),),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18,),),
                const Spacer(flex: 1,),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black38, size: 15,),
                const SizedBox(width: 10,),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
