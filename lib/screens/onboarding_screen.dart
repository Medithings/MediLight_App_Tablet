import 'package:ble_uart/screens/scan_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:lottie/lottie.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});
  final Color kDarkBlueColor = const Color(0xFF053149);

  @override
  Widget build(BuildContext context) {

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: OnBoardingSlider(
        headerBackgroundColor: Colors.white,
        finishButtonText: 'Register',
        finishButtonStyle: const FinishButtonStyle(backgroundColor: Colors.blueGrey,),
        onFinish: (){
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => const ScanScreen()),
          );
        },
        skipTextButton: Text(
          'Skip',
          style: TextStyle(
            fontSize: 17,
            color: kDarkBlueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          'Login',
          style: TextStyle(
            fontSize: 17,
            color: kDarkBlueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailingFunction: (){
          Navigator.push(context, CupertinoPageRoute(builder: (context) => const ScanScreen(),),);
        },
        controllerColor: kDarkBlueColor,
        totalPage: 4,

        background: [
          Column(
            children: [
              const SizedBox(height: 60,),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.97,
                height: MediaQuery.of(context).size.height*0.38,
                child: Lottie.asset('assets/lottie/first.json', width: 300, height: 230, fit: BoxFit.fill,),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 5,),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.97,
                height: MediaQuery.of(context).size.height*0.48,
                child: Lottie.asset('assets/lottie/second.json', width: 300, height: 230, fit: BoxFit.fill,),
              ),
            ],
          ),
          Column(
            children: [
              const SizedBox(height: 70,),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.97,
                height: MediaQuery.of(context).size.height*0.38,
                child: Lottie.asset('assets/lottie/third.json', width: 300, height: 230, fit: BoxFit.fill,),
              ),
            ],
          ),
          Column(
            children: [
              const SizedBox(height: 70,),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.97,
                height: MediaQuery.of(context).size.height*0.4,
                child: Lottie.asset('assets/lottie/fourth.json', width: 300, height: 230, fit: BoxFit.fill,),
              ),
            ],
          ),
        ],

        speed: 1,

        pageBodies: [
          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                Text(
                  'First',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kDarkBlueColor,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'First boarding page',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                Text(
                  'Second',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kDarkBlueColor,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Second boarding page',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                Text(
                  'Third',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kDarkBlueColor,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Third boarding page',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                Text(
                  'Fourth',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kDarkBlueColor,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Fourth boarding page',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}