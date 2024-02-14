import 'package:ble_uart/screens/ai_screen.dart';
import 'package:ble_uart/screens/first_connect_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  late SharedPreferences pref;

  void _submit(){
    final validationSuccess = _fk.currentState?.validate();

    if(validationSuccess == true){
      _fk.currentState?.save();

      name = _fk.currentState?.fields["name"]?.value;
      age = _fk.currentState?.fields["age"]?.value;
      height = _fk.currentState?.fields["height"]?.value;
      weight = _fk.currentState?.fields["weight"]?.value;
      gender = _fk.currentState?.fields["gender"]?.value;
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
    return Column(
      children: [
        FormBuilder(
          key: _fk,
          child: Column(
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
                decoration: const InputDecoration(labelText: 'Insert height', hintText: "ex) 178"),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
              ),
              const SizedBox(height: 15,),
              FormBuilderTextField(
                keyboardType: TextInputType.number,
                name: 'weight',
                decoration: const InputDecoration(labelText: 'Insert weight', hintText: "ex) 70"),
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
                validator: (value){
                  FormBuilderValidators.required();
                },
                initialValue: 'm',
              ),
              const SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
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
                  const SizedBox(width: 10,),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}