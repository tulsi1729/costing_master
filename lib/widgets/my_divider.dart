import 'package:flutter/material.dart';

class MyDivider extends StatelessWidget {
  final double height;
  const MyDivider({super.key, this.height = 15});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: height,
        ),
        SizedBox(
          height: height,
        ),
      ],
    );
  }
}
