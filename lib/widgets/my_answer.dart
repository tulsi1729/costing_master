import 'package:costing_master/constants.dart';
import 'package:flutter/material.dart';

class MyAnswer extends StatelessWidget {
  final double answer;
  const MyAnswer({super.key, required this.answer});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Center(
        child: Text(
          '${answer.toStringAsFixed(2)} $inrSymbol',
        ),
      ),
    );
  }
}
