import 'package:flutter/material.dart';

class AccountSettingsTile extends StatelessWidget {
  const AccountSettingsTile({super.key, required this.stIcon, required this.title, required this.bgColor, required this.info});

  final IconData stIcon;
  final String title;
  final Color bgColor;
  final String info;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(left: 50.0),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                      color: bgColor,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Icon(stIcon, color: Colors.white, size: 50,),
                  ),
                ),
              ),
              const SizedBox(width: 25,),
              Text(title, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 25,),),
              const Spacer(flex: 1,),
              Text(info, style: const TextStyle(color: Colors.grey, fontSize: 25),),
              const SizedBox(width: 15,),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black38, size: 25,),
              const SizedBox(width: 40,),
            ],
          ),
        ],
      ),
    );
  }
}
