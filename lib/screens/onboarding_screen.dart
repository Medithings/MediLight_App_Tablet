import 'package:ble_uart/screens/register_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:lottie/lottie.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});
  final Color kDarkBlueColor = const Color(0xFF053149);

  @override
  Widget build(BuildContext context) {

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
      ),
      home: OnBoardingSlider(
        centerBackground: true,
        headerBackgroundColor: Colors.white,
        finishButtonText: 'Register',
        finishButtonStyle: const FinishButtonStyle(backgroundColor: Colors.blueGrey,),
        onFinish: (){
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
                builder: (context) => const RegisterScreen()),
          );
        },
        skipTextButton: Text(
          'skip',
          style: TextStyle(
            fontSize: 23,
            color: kDarkBlueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Login 기능은 필요 없어서
        // trailing: Text(
        //   'Login',
        //   style: TextStyle(
        //     fontSize: 17,
        //     color: kDarkBlueColor,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        // trailingFunction: (){
        //   Navigator.push(context, CupertinoPageRoute(builder: (context) => const ScanScreen(),),);
        // },
        controllerColor: kDarkBlueColor,
        totalPage: 4,
        pageBackgroundColor: Colors.white,
        background: [
          // Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   crossAxisAlignment: CrossAxisAlignment.center,
          //   children: [
          //     const SizedBox(height: 60,),
          //     Container(
          //       // color: Colors.red,
          //       width: MediaQuery.of(context).size.width*0.97,
          //       height: MediaQuery.of(context).size.height*0.46,
          //       child: Lottie.asset('assets/lottie/first.json', width: 300, height: 230, fit: BoxFit.fill,),
          //     ),
          //   ],
          // ),
          Container(
            // color: Colors.red,
            width: MediaQuery.of(context).size.width*0.97,
            height: MediaQuery.of(context).size.height*0.54,
            child: Lottie.asset('assets/lottie/first.json', width: 300, height: 230, fit: BoxFit.fill,),
          ),
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.center,
          //   children: [
          //     const SizedBox(height: 50,),
          //     Row(
          //       children: [
          //         const SizedBox(width: 15,),
          //         SizedBox(
          //           width: MediaQuery.of(context).size.width*0.90,
          //           height: MediaQuery.of(context).size.height*0.54,
          //           child: Lottie.asset('assets/lottie/second.json', fit: BoxFit.fill,),
          //         ),
          //       ],
          //     ),
          //   ],
          // ),
          SizedBox(
            width: MediaQuery.of(context).size.width*0.5,
            height: MediaQuery.of(context).size.height*0.6,
            child: Lottie.asset('assets/lottie/second.json', fit: BoxFit.fill,),
          ),
          // Column(
          //   children: [
          //     const SizedBox(height: 70,),
          //     SizedBox(
          //       width: MediaQuery.of(context).size.width*0.97,
          //       height: MediaQuery.of(context).size.height*0.38,
          //       child: Lottie.asset('assets/lottie/third.json', width: 300, height: 230, fit: BoxFit.fill,),
          //     ),
          //   ],
          // ),
          SizedBox(
            width: MediaQuery.of(context).size.width*0.97,
            height: MediaQuery.of(context).size.height*0.6,
            child: Lottie.asset('assets/lottie/third.json', width: 300, height: 230, fit: BoxFit.fill,),
          ),
          // Column(
          //   children: [
          //     const SizedBox(height: 70,),
          //     SizedBox(
          //       width: MediaQuery.of(context).size.width*0.97,
          //       height: MediaQuery.of(context).size.height*0.4,
          //       child: Lottie.asset('assets/lottie/fourth.json', width: 300, height: 230, fit: BoxFit.fill,),
          //     ),
          //   ],
          // ),
          SizedBox(
            width: MediaQuery.of(context).size.width*0.97,
            height: MediaQuery.of(context).size.height*0.54,
            child: Lottie.asset('assets/lottie/fourth.json', width: 300, height: 230, fit: BoxFit.fill,),
          ),
        ],

        speed: 1,

        pageBodies: [
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
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
                const SizedBox(height: 150,),
              ],
            ),
          ),

          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
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
                const SizedBox(height: 150,),
              ],
            ),
          ),

          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
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
                const SizedBox(height: 150,),
              ],
            ),
          ),

          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
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
                const SizedBox(height: 150,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
