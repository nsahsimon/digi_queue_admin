import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {

  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final Function validator;
  final TextInputType inputType;

  MyTextField({this.hintText = '', this.controller, this.labelText = '', this.obscureText = false, this.validator, this.inputType = TextInputType.text});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          keyboardType: inputType,
          obscureText: obscureText,
          cursorColor: Colors.black,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            labelText: labelText,
          ),
          validator: validator
        ),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
