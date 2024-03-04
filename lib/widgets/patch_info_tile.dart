import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PatchInfoTile extends StatelessWidget {
  const PatchInfoTile({super.key, required this.info, required this.title});

  final String title;
  final String info;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const SizedBox(width: 16,),
              Text(title, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18,),),
              const Spacer(flex: 1,),
              Text(info, style: const TextStyle(color: Colors.grey, fontSize: 18),),
              const SizedBox(width: 16,),
            ],
          ),
        ],
      ),
    );
  }
}
