
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:intl/intl.dart';
import '../utils/shared_prefs_utils.dart';

class CatheterCountScreen extends StatefulWidget {
  const CatheterCountScreen({super.key});

  @override
  State<CatheterCountScreen> createState() => _CatheterCountScreenState();
}

class _CatheterCountScreenState extends State<CatheterCountScreen> {

  final totalControl = TextEditingController();
  final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final FocusNode totalTextFocus = FocusNode();
  final FocusNode receiveTextFocus = FocusNode();
  final FocusNode endTextFocus = FocusNode();
  late DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1);
  late DateTime? savedDate;

  bool receivedSpeedButtonToday = true;
  bool endSpeedButton1Month = true;

  final pref = SharedPrefsUtil();
  late bool testingPref;

  late bool yesNo = true;
  late int totalC = 0;
  final txtController = TextEditingController();
  late int dayPer = 0;
  late int initialC = 0;
  late int initPer = 0;

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    print("init start");
    setState(() {
      if (pref.hasCatheter) {
        print("pref has catheter");
        yesNo = pref.catheter;
        totalC = pref.totalC;
        initialC = pref.initialC;
        dayPer = pref.per;
        initPer = pref.initPer;
        savedDate = DateTime.parse(pref.savedDate);
        endDate = DateTime.parse(pref.endDate);
        _calculation();
      }
      else {
        print("pref has no catheter");
        yesNo = false;
        totalC = 0;
        dayPer = 0;
        initialC = 0;
        initPer = 0;
      }
    });
    print("yesNo: $yesNo");
    print("init done");
    // TODO: calculation
    print("after widgets binding");
    // TODO: implement initState
    super.initState();
  }

  void _calculation(){
    print("-----calculation-----");

    if(savedDate!.difference(todayDate) >= const Duration(days: 1)){
      setState(() {
        savedDate = DateTime(todayDate.year, todayDate.month, todayDate.day -1);
      });
      pref.savedDate = DateFormat("yyyyMMdd").format(todayDate).toString();
    }

    if(todayDate.difference(savedDate!) >= const Duration(days: 1) && endDate.difference(todayDate) >= const Duration(days: 1)){
      print("[calculation] end date $endDate");
      print("[calculation] today date $todayDate");
      print("[calculation] saved date $savedDate");
      int diff = endDate.difference(todayDate).inDays + 1;
      print("[calculation] date diff $diff");
      print("[calculation] totalC ${pref.totalC}");
      int per = (pref.totalC / diff).floor();
      print("[calculation] per $per");
      pref.per = per;
      pref.initPer = per;
      pref.savedDate = DateFormat("yyyyMMdd").format(todayDate).toString();

      setState(() {
        dayPer = pref.per;
        initPer = pref.per;
      });
    }

    // TODO: todayDate == endDate
    if(todayDate == endDate){
      print("[calculation] today == endDate");
      pref.per = totalC;
      pref.initPer = totalC;
      setState(() {
        dayPer = pref.per;
        initPer = pref.initPer;
      });
    }

    if(todayDate.difference(endDate) >= const Duration(days: 1) ){
      print("RESET");
      setState(() {
        yesNo = false;
        totalC = 0;
        dayPer = 0;
        initialC = 0;
        initPer = 0;
      });
      pref.removeCatheterSP;
    }

  }

  void _setTotal(){
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context){
          return GestureDetector(
            onTap: (){
              FocusScope.of(context).unfocus();
            },
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: const Text("Catheter status", style: TextStyle(fontSize: 30,),),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20,),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("1️⃣ Enter your total catheter", style: TextStyle(fontSize: 25,),),
                        ],
                      ),
                      const SizedBox(height: 10,),
                      TextField(
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        controller: txtController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'total catheter ex) 30',
                          labelStyle: TextStyle(fontSize: 20,),
                        ),
                      ),

                      const SizedBox(height: 50,),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("2️⃣ Select the due date", style: TextStyle(fontSize: 25,),),
                        ],
                      ),
                      DatePickerWidget(
                        looping: true,
                        firstDate: DateTime(todayDate.year, todayDate.month, todayDate.day + 1),
                        dateFormat: "dd/MMMM/yyyy",
                        onChange: (DateTime newDate, _){
                          setState(() {
                            endDate = newDate;
                          });
                          print(endDate);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: (){
                        txtController.clear();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel", style: TextStyle(fontSize: 20,),),
                    ),
                    TextButton(
                      onPressed: (){
                        if(txtController.text.isEmpty){
                          pref.totalC = 0;
                          pref.initialC = 0;
                        }
                        else{
                          pref.totalC = int.parse(txtController.text);
                          pref.initialC = int.parse(txtController.text);
                        }

                        pref.endDate = DateFormat("yyyyMMdd").format(endDate).toString();
                        print("end date ${pref.endDate}");

                        pref.catheter = true;
                        print("saved");

                        bool? testprint = pref.catheter;
                        print(testprint);

                        int diff = endDate.difference(todayDate).inDays + 1;
                        print("date diff $diff");

                        int per = (pref.totalC / diff).floor();

                        pref.per = per;
                        print("per $per ${pref.per}");
                        pref.initPer = per;
                        pref.savedDate = DateFormat("yyyyMMdd").format(todayDate).toString();

                        setState(() {
                          yesNo = pref.catheter;
                          totalC = pref.totalC;
                          initialC = pref.totalC;
                          dayPer = pref.per;
                          initPer = pref.per;
                        });
                        txtController.clear();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Ok", style: TextStyle(fontSize: 20,),),
                    ),
                  ],
                ),
              ],
            ),
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
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("[How To Use]"),
            content: const Text(
              """
❗️ INITIAL SETTING
1️⃣ Press the '0' which is located in the middle of the screen.
2️⃣ Enter the total number of catheters and the due date for them.
(until when do you plan to use the catheters)

🥳 Now you're ready to use!

❗️ HOW TO USE
   *  Simply press '1 Used' when you use your catheter.
   *  If you want to modify total number of catheter by pressing the
   number which is located in the middle of the screen.
   *  You can also see the status of the catheter in Home page.
              """,
              style: TextStyle(fontSize: 20,),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    print("start build");

    return Scaffold(
      appBar: AppBar(
        title: const Text("    Catheter Counting", style: TextStyle(fontSize: 35,),),
        toolbarHeight: 120,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 60.0),
            child: IconButton(onPressed: _howToUse, icon: const Icon(Icons.info, size: 40,),),
          )
        ],
        shape: const Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30,),
            const Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 80),
                  child:  Text("Per day", style: TextStyle(fontSize: 33, fontWeight: FontWeight.bold),),
                ),
              ],
            ),

            const SizedBox(height: 30,),
            InkWell(
              onTap: _setTotal,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Text("$dayPer", style: const TextStyle(fontSize: 250, fontWeight: FontWeight.bold),),
            ),

            const SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 90,
                  width: 200,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff50586C),
                    ),
                    onPressed: (){
                      setState(() {
                        if(yesNo && totalC > 0) {
                          dayPer--;
                          totalC--;
                          pref.per = dayPer;
                          pref.totalC = totalC;
                        }
                      });
                    },
                    child: const Text("1 Used", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white,),),
                  ),
                ),
                const SizedBox(width: 30,),
                SizedBox(
                  height: 90,
                  width: 90,
                  child: Ink(
                    decoration: const ShapeDecoration(
                      color: Color(0xffDCE2F0),
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      tooltip: "Undo",
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: (){
                        if(dayPer < initPer){
                          setState(() {
                            totalC++;
                            dayPer++;
                          });
                          pref.totalC = totalC;
                          pref.per = dayPer;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(left: 80, right: 30, bottom: 10, top: 100,),
              child: Row(
                children: [
                  const Text("Total Catheter", style: TextStyle(fontSize: 25,),),
                  const Spacer(flex: 1,),
                  yesNo? Text("${pref.totalC} / ${pref.initialC}", style: const TextStyle(fontSize: 25,),) : const Text("Empty", style: TextStyle(fontSize: 25,),),
                  const SizedBox(width: 80,),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 80, right: 30, bottom: 10,),
              child: Row(
                children: [
                  const Text("Daily Status", style: TextStyle(fontSize: 25,),),
                  const Spacer(flex: 1,),
                  yesNo? Text("${pref.per} / ${pref.initPer}", style: const TextStyle(fontSize: 25,),) : const Text("Empty", style: TextStyle(fontSize: 25,),),
                  const SizedBox(width: 80,),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 80, right: 30, bottom: 10,),
              child: Row(
                children: [
                  const Text("Due Date", style: TextStyle(fontSize: 25,),),
                  const Spacer(flex: 1,),
                  yesNo? Text("${pref.endDate[0]}${pref.endDate[1]}${pref.endDate[2]}${pref.endDate[3]} / ${pref.endDate[4]}${pref.endDate[5]} / ${pref.endDate[6]}${pref.endDate[7]}", style: const TextStyle(fontSize: 25,),)
                      : const Text("Empty", style: TextStyle(fontSize: 25,),),
                  const SizedBox(width: 80,),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 80, right: 30,),
              child: Row(
                children: [
                  const Text("D-day", style: TextStyle(fontSize: 25,),),
                  const Spacer(flex: 1,),
                  yesNo?
                  endDate != todayDate? Text("D-${endDate.difference(todayDate).inDays + 1}", style: const TextStyle(fontSize: 25,),)
                      : const Text("D-DAY", style: TextStyle(fontSize: 25,),)
                      : const Text("Empty", style: TextStyle(fontSize: 25,),),
                  const SizedBox(width: 80,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
