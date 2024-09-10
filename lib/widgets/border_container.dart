import 'package:flutter/material.dart';

class BorderContainer extends StatelessWidget {
  final Color color;
  final Widget child;
  const BorderContainer(
      {super.key, this.color = Colors.red, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: color)),
      child: child,
    );
  }
}
