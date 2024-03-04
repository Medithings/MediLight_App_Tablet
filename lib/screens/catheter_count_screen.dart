import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatheterCountScreen extends StatefulWidget {
  const CatheterCountScreen({super.key});

  @override
  State<CatheterCountScreen> createState() => _CatheterCountScreenState();
}

class _CatheterCountScreenState extends State<CatheterCountScreen> {
  int totalC = 0;
  final txtController = TextEditingController();
  late SharedPreferences pref;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    prefGetter();
  }

  void prefGetter() async {
    pref = await SharedPreferences.getInstance();

    try{
      setState(() {
        if(pref.getInt("totalC") != null){
          totalC = pref.getInt("totalC")!;
        }
        else{
          pref.setInt("totalC", 0);
        }
      });
    }catch(e){
      if (kDebugMode) {
        print("error : $e");
      }
    }
  }

  void _setTotal(){
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("Enter your total catheter"),
            content: TextField(
              keyboardType: TextInputType.number,
              controller: txtController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'total catheter ex) 30',
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: (){
                  txtController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: (){
                  setState(() {
                    totalC = int.parse(txtController.text);
                  });
                  pref.setInt("totalC", totalC);
                  txtController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text("Ok"),
              ),
            ],
          );
        }
    );
  }

  void _howToUse(){
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("[How To Use]"),
            content: const Text(
              "If you use one Catheter then press button 1 Used.\nIf you want to modify total number of catheter, then just simply press the number.",
              style: TextStyle(fontSize: 20,),
            ),
            actions: [
              ElevatedButton(
                onPressed: (){
                  txtController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text("Ok"),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catheter Counting"),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(onPressed: _howToUse, icon: const Icon(Icons.info),),
          )
        ],
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Total", style: TextStyle(fontSize: 30,),),
                const SizedBox(height: 20,),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: _setTotal,
                  focusColor: Colors.transparent,
                  child: Text("$totalC", style: const TextStyle(fontSize: 150, fontWeight: FontWeight.bold),),
                ),
                const SizedBox(height: 50,),
                SizedBox(
                  height: 60,
                  width: 150,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(40, 88, 123, 1),
                    ),
                    onPressed: (){
                      if (totalC > 0) {
                        pref.setInt("totalC", --totalC);
                      }

                      setState(() {
                        totalC = pref.getInt("totalC")!;
                      });
                    },
                    child: const Text("1 Used", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,),),
                  ),
                ),
                const SizedBox(height: 20,),
                // FilledButton(
                //   style: FilledButton.styleFrom(
                //     backgroundColor: const Color.fromRGBO(74, 88, 153, 1),
                //   ),
                //   onPressed: (){
                //     _setTotal();
                //   },
                //   child: const Text("Change total", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,),),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
