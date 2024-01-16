import 'package:ble_uart/widgets/register_form_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ListView(
              children: const [
                SizedBox(height: 40,),
                Image(image: AssetImage('assets/logo300.png'), height: 200,),
                RegisterFormField(),
                SizedBox(height: 70,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

