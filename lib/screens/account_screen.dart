import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/account_settings_tile.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

enum Gender {male, female}

class _AccountScreenState extends State<AccountScreen> {

  late SharedPreferences pref;
  late String accountName="";
  late String guardianEmail="";
  late String age="";
  late String weight="";
  late String height="";
  late String gender="";
  final Gender _g = Gender.male;

  final txtController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    prefGetter();
  }

  void _changeAlert(String which){
    String matchTitle="";
    String matchLabel="";

    if(which == "name") {
      matchTitle = "Modify your name";
      matchLabel = "Name ex) Isaac";
    }
    if(which == "age") {
      matchTitle = "Modify your age";
      matchLabel = "Age ex) 24";
    }
    if(which == "height") {
      matchTitle = "Modify your height";
      matchLabel = "Height(cm) ex) 170";
    }
    if(which == "weight") {
      matchTitle = "Modify your weight";
      matchLabel = "Weight(kg) ex) 70";
    }
    if(which == "gender") {
      matchTitle = "Modify your gender";
    }
    if(which == "guardian") {
      matchTitle = "Modify your guardian's email";
      matchLabel = "Guardian's email ex) abc@def.com";
    }

      showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context){
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: Text(matchTitle),

          content:
          SizedBox(
            height: which == "guardian" ? 120:80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                which == "guardian"?
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("[ Current guardian's email address ]"),
                        Text(guardianEmail, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                        const SizedBox(height: 10,),
                      ],
                    )
                    : Container(),
                which != "gender"?
                TextField(
                  keyboardType: which == "name" || which == "guardian"? TextInputType.text : TextInputType.number,
                  controller: txtController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: matchLabel,
                  ),
                )
                : Container(
                  child: gender == "m"? const Text("Do you want to change your gender to Female?") : const Text("Do you want to change your gender to Male?"),
                ),
              ],
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
                if(which == "name") pref.setString("name", txtController.text);
                if(which == "age") pref.setString("age", txtController.text);
                if(which == "height") pref.setString("height", txtController.text);
                if(which == "weight") pref.setString("weight", txtController.text);
                if(which == "guardian") pref.setString("guardianEmail", txtController.text);

                if(which == "gender") {
                  if(gender == "f"){
                    pref.setString("gender", "m");
                  } else {
                    pref.setString("gender", "f");
                  }
                }

                txtController.clear();
                prefGetter();
                Navigator.of(context).pop();
              },
              child: const Text("Ok"),
            ),
          ],
        );
      }
    );
  }

  void prefGetter() async {
    pref = await SharedPreferences.getInstance();

    try{
      setState(() {
        if(pref.getString("name") != null){
          accountName = pref.getString("name")!;
        } else {
          accountName = "No name";
        }

        if(pref.getString("guardianEmail") != null){
          guardianEmail = pref.getString("guardianEmail")!;
        } else {
          guardianEmail = "guardian not registered";
        }

        if(pref.getString("age") != null){
          age = pref.getString("age")!;
        } else {
          age = "";
        }

        if(pref.getString("height") != null){
          height = pref.getString("height")!;
        } else {
          height = "";
        }

        if(pref.getString("weight") != null){
          weight = pref.getString("weight")!;
        } else {
          weight = "";
        }

        if(pref.getString("gender") != null){
          gender = pref.getString("gender")!;
        } else {
          gender = "";
        }

      });

    }catch(e){
      if (kDebugMode) {
        print("error : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        centerTitle: true,
        leading: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueAccent,),
              Text("Settings", style: TextStyle(fontSize: 18, color: Colors.blueAccent),),
            ],
          ),
          onTap: (){
            Navigator.of(context).pop();
          },
        ),
        leadingWidth: 120,
      ),

      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10,),
              const Icon(Icons.account_circle_rounded, size: 100, color: Colors.grey,),
              Text(accountName, style: const TextStyle(fontSize: 30,),),
              const SizedBox(height: 30,),
              InkWell(
                onTap: (){
                  _changeAlert("name");
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                      bottom: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                    ),
                  ),
                  child: AccountSettingsTile(stIcon: Icons.manage_accounts_rounded, title: "Name", bgColor: Colors.grey, info: accountName,),
                ),
              ),
              InkWell(
                onTap: (){
                  _changeAlert("age");
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: AccountSettingsTile(stIcon: Icons.manage_accounts_rounded, title: "Age", bgColor: Colors.grey, info: age,),
                ),
              ),
              InkWell(
                onTap: (){
                  _changeAlert("height");
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                      bottom: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                    ),
                  ),
                  child: AccountSettingsTile(stIcon: Icons.manage_accounts_rounded, title: "Height", bgColor: Colors.grey, info: "$height cm",),
                ),
              ),
              InkWell(
                onTap: (){
                  _changeAlert("weight");
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                    ),
                  ),
                  child: AccountSettingsTile(stIcon: Icons.manage_accounts_rounded, title: "Weight", bgColor: Colors.grey, info: "$weight kg",),
                ),
              ),
              InkWell(
                onTap: (){
                  _changeAlert("gender");
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                    ),
                  ),
                  child: AccountSettingsTile(stIcon: Icons.manage_accounts_rounded, title: "Gender", bgColor: Colors.grey, info: gender=='m'?"Male":"Female",),
                ),
              ),
              const SizedBox(height: 20,),
              InkWell(
                onTap: (){
                  _changeAlert("guardian");
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                      bottom: BorderSide(color: Color.fromRGBO(225, 225, 225, 1),),
                    ),
                  ),
                  child: AccountSettingsTile(stIcon: Icons.email, title: "Guardian Email", bgColor: Colors.grey, info: "",),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

