import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final String labelText;
  final String? suffixText;
  final double labelPadding;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  const MyTextField({
    super.key,
    required this.labelText,
    this.suffixText,
    this.onChanged,
    this.controller,
    this.labelPadding = 2,
  });
  

  @override
  Widget build(BuildContext context) {


    return Flexible(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          label: Wrap(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(labelPadding),
                  child: Text(
                    labelText,
                    // style: const TextStyle(fontSize: 18, height: 0.9),
                    style: const TextStyle(fontSize: 12, height: 0.9),
                  ),
                ),
              ),
            ],
          ),
          suffixText: suffixText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
