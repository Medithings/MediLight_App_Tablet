import 'package:ble_uart/screens/training_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {

  List<String> measureLog = [];
  final txtController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String timeStamp(){
    DateTime now = DateTime.now();
    String formattedTime = DateFormat.Hms().format(now);
    return formattedTime;
  }

  void _confirm(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("Confirming input data"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("측정 용량: ${txtController.text} ml"),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: (){
                  setState(() {
                    String log = "";
                    log += timeStamp();
                    log += ":  ${txtController.text} ml";
                    measureLog.add(log);
                    txtController.clear();
                    Navigator.of(context).pop();
                  });
                },
                child: const Text("측정"),
              ),
            ],
          );
        }
    );
  }

  void _zeroConfirm(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("Zero confirm?"),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("측정 용량: 0 ml"),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: (){
                  setState(() {
                    String log = "";
                    log += timeStamp();
                    log += ":  0 ml";
                    measureLog.add(log);
                    txtController.clear();
                    Navigator.of(context).pop();
                  });
                },
                child: const Text("측정"),
              ),
            ],
          );
        }
    );
  }

  void trainConfirm(){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text("학습을 시작하시겠습니까?"),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("확인을 누르면 학습 페이지로 넘어갑니다"),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: (){
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const TrainingScreen()),
                  );
                },
                child: const Text("확인"),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_scrollController.hasClients){
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 10,),
            curve: Curves.linear);
      }
    });

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Row(
            children: [
              SizedBox(width: 20,),
              Text("인공지능 학습", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25,),),
            ],
          ),
          elevation: 0.0,
          scrolledUnderElevation: 0.0,
          backgroundColor: Colors.white,
          centerTitle: false,
          toolbarHeight: 80,
        ),

        body: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ListView(
              // mainAxisAlignment: MainAxisAlignment.end,
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black12,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 20, top: 20,),
                    child: Text(
                      "안내사항\n의료진의 안내에 따라주세요.",
                      style: TextStyle(color: Colors.black54, fontSize: 17, ),
                    ),
                  ),
                ),
                // const Spacer(flex: 8,),
                const Divider(thickness: 2.0, height: 75,),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 80,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(126, 189, 194, 1),
                    ),
                    onPressed: _zeroConfirm,
                    child: const Text("0ml   측정", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                  ),
                ),
                const SizedBox(height: 30,),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10,),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: txtController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '측정 용량을 적어주세요',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(35, 31, 32, 1),
                        ),
                        onPressed: _confirm,
                        child: const Text("확인", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10,),

                const Divider(thickness: 2.0, height: 80,),

                const Padding(
                  padding: EdgeInsets.only(left: 10, bottom: 20,),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Icon(Icons.book),
                        SizedBox(width: 10,),
                        Text("학습 로그", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25,),),
                      ],
                    ),
                  ),
                ),

                measureLog.isNotEmpty ?
                Padding(
                  padding: const EdgeInsets.only(left: 10,),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black12,
                    ),
                    height: 200,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 25, top: 25),
                        child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: measureLog.length,
                            reverse: true,
                            itemBuilder: (context, index){
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    measureLog[index],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 15,),
                                ],
                              );
                            }
                        ),
                      ),
                    ),
                  ),
                ): Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black12,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 20, top: 20,),
                      child: Text("아직 측정된 데이터가 없습니다", style: TextStyle(fontSize: 17, color: Colors.black54,),),
                    ),
                  ),
                ),
                // const Spacer(flex: 1,),

                measureLog.length >= 2 ?
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 20,),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 70,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                      ),
                      onPressed: (){
                        // TODO : Alert
                      },
                      child: const Text("학습 시작", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                    ),
                  ),
                ): Container(),

                const SizedBox(height: 50,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
