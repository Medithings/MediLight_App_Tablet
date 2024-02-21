import 'package:ble_uart/screens/ai_screen.dart';
import 'package:ble_uart/screens/first_connect_screen.dart';
import 'package:ble_uart/screens/guardian_register_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../screens/scan_screen.dart';

class RegisterFormField extends StatefulWidget {
  const RegisterFormField({super.key});

  @override
  State<RegisterFormField> createState() => _RegisterFormFieldState();
}

class _RegisterFormFieldState extends State<RegisterFormField> {
  final _fk = GlobalKey<FormBuilderState>();
  String name = "";
  String age = "";
  String height = "";
  String weight = "";
  String gender = "";
  bool guardian = false;

  // TODO: 이후에 GuardianRegisterScreen 페이지를 작업한다면 이렇게 email로 받지 않을 것이기 때문에 List String으로 한 것임
  List<String> guardianInformString =["Registered", "Not applicable"];
  String guardianEmail = "";

  final formKey = GlobalKey<FormState>();

  final emailControler = TextEditingController();
  Color btnbackgroundColor = Colors.grey.shade300;
  Color btnTextColor = Colors.black26;

  bool _sendUpdates = false;

  bool btnVisible = false;

  late SharedPreferences pref;

  String? validateEmail(String? value) {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);

    return value!.isEmpty || !regex.hasMatch(value)
        ? 'Enter a valid email address'
        : null;
  }

  void _submit(){
    final validationSuccess = _fk.currentState?.validate();

    if(validationSuccess == true){
      _fk.currentState?.save();

      name = _fk.currentState?.fields["name"]?.value;
      age = _fk.currentState?.fields["age"]?.value;
      height = _fk.currentState?.fields["height"]?.value;
      weight = _fk.currentState?.fields["weight"]?.value;
      gender = _fk.currentState?.fields["gender"]?.value;
      guardianEmail = emailControler.text ??= "";
    }

    _confirmDialogue();
  }

  void _confirmDialogue(){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context){
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: const Text("Confirm your input data"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: $name"),
              Text("Age: $age"),
              Text("Height: $height"),
              Text("Weight: $weight"),
              Text("Gender: $gender"),
              Text("Guardian: ${guardian? guardianEmail: guardianInformString[1]}"),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () async{
                final navigator = Navigator.of(context);
                /* TODO:
                     1. await 해서 로컬 데이터 저장
                     2. Navigate
                */
                pref = await SharedPreferences.getInstance();
                pref.setString('name', name);
                pref.setString('age', age);
                pref.setString('height', height);
                pref.setString('weight', weight);
                pref.setString('gender', gender);

                // TODO: 일후 Guardian에 대한 정보를 받아왔는지에 대한 확인이 필요했지만 지금은 필요없음
                // pref.setBool('guardian', guardian);


                /* TODO: 이후 로그인 서비스가 이루어지면 로그인하고 보호자의 계정을 등록할 수 있는 GuardianRegisterScreen
                *  일단은 이메일로 할 것이 이기 때문에 guardian이 true이면 보호자 이메일을 등록하도록
                */
                guardian? pref.setString('guardianEmail', guardianEmail) : pref.setString('guardianEmail', "");

                // TODO: 이게 보호자의 계정을 등록할 수 있는 페이지로 redirection 해주는 것
                // guardian?
                //   navigator.pushReplacement(MaterialPageRoute(builder: (context) => const GuardianRegisterScreen(),),)
                //   : navigator.pushReplacement(MaterialPageRoute(builder: (context) => const FirstConnectScreen(),),);
                navigator.pushReplacement(MaterialPageRoute(builder: (context) => const FirstConnectScreen(),),);
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
    return FormBuilder(
      key: _fk,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FormBuilderTextField(
            name: 'name',
            decoration: const InputDecoration(labelText: 'Insert name', hintText: "ex) David"),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 15,),
          FormBuilderTextField(
            keyboardType: TextInputType.number,
            name: 'age',
            decoration: const InputDecoration(labelText: 'Insert age', hintText: "ex) 25"),
            validator: FormBuilderValidators.compose([
              // FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 15,),
          FormBuilderTextField(
            keyboardType: TextInputType.number,
            name: 'height',
            decoration: const InputDecoration(labelText: 'Insert height (cm)', hintText: "ex) 178"),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 15,),
          FormBuilderTextField(
            keyboardType: TextInputType.number,
            name: 'weight',
            decoration: const InputDecoration(labelText: 'Insert weight (kg)', hintText: "ex) 70"),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 15,),
          FormBuilderRadioGroup(
            name: 'gender',
            options: const <FormBuilderFieldOption>[
              FormBuilderFieldOption(
                value: 'm',
                child: Text('Male'),
              ),
              FormBuilderFieldOption(
                value: 'f',
                child: Text('Female'),
              ),
            ],
            initialValue: 'm',
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ])
          ),

          const SizedBox(height: 40,),

          FormBuilderField<bool>(
            name: 'terms',
            builder: (FormFieldState field) {
              return ListTileTheme(
                horizontalTitleGap: 5.0,
                child: CheckboxListTile(
                  title: const Text('I want to register my guardian'),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: guardian,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value){
                    setState(() {
                      guardian = !guardian;
                      emailControler.clear();
                    });
                  },
                ),
              );
            },
          ),

          guardian?
          Column(
            children: [
              const SizedBox(height: 10,),
              TextFormField(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp("[0-9@a-zA-Z.]")),
                ],
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: emailControler,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close,color: Colors.grey,size: 18,),
                    onPressed: () => emailControler.clear(),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  hintText: "Guardian's email",
                  hintStyle: const TextStyle(fontSize: 16,color:Colors.black45),
                  fillColor: Colors.grey.shade200,
                  filled: true,
                  counterText: "",
                  focusedBorder:OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.transparent, width: 1.0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: validateEmail,
              ),
            ],
          )
          : Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black12,
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 10,),
                child: Text(
                  "If you register your guardian,\nyour guardian could receive an email when the time you need to measure.",
                  style: TextStyle(color: Colors.black54, fontSize: 17, ),
                ),
              ),
            ),
          ),

          // TODO: GuardianRegisterScreen이 필요할 때 사용
          // guardian? Container(
          //   width: MediaQuery.of(context).size.width * 0.8,
          //   height: 130,
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(20),
          //     color: Colors.black12,
          //   ),
          //   child: const Padding(
          //     padding: EdgeInsets.only(left: 20, top: 15, right: 20),
          //     child: Text(
          //       "[Notice]\nEach of the user and the guardian should have their own KakaoTalk account",
          //       style: TextStyle(color: Colors.black54, fontSize: 17, ),
          //     ),
          //   ),
          // ): Container(),

          const SizedBox(height: 20,),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 70,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blueGrey),

              ),
              onPressed: (){
                if(_fk.currentState!.saveAndValidate()){
                  if (kDebugMode) {
                    print(_fk.currentState?.value);
                  }
                  _submit();
                } else{
                  if (kDebugMode) {
                    print(_fk.currentState?.value);
                    print("validation failed");
                  }
                }
              },
              child: const Text('Submit', style: TextStyle(color: Colors.white),),
            ),
          ),
          const SizedBox(width: 10,),
        ],
      ),
    );
  }
}