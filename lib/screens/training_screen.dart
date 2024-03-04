import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bottom_navigation_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late SharedPreferences pref;
  Route route = MaterialPageRoute(builder: (context) => const BottomNavigationScreen());
  // TODO : HomeScreen에서 Service 찾고 Char 알맞은 것 매칭해서 tx listen, rx write 했던 것처럼 필요한 값들 가지고 와서 AI model parameter로 전달

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPref();
  }

  void getPref() async {
    pref = await SharedPreferences.getInstance();
    pref.setBool('registered', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 80,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromRGBO(126, 189, 194, 1),
            ),
            onPressed: (){
              Navigator.pushReplacement(context, route);
            },
            child: const Text("GO HOME", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
          ),
        ),
      ),
    );
  }
}
