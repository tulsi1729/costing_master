import 'package:flutter/material.dart';

class Preview extends StatefulWidget {
  Preview({super.key});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            child: const Text("Save to image "),
          ),
          Text("sariName"),
        ],
      ),
    );
  }
}
