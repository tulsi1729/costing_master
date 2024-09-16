import 'dart:developer';

import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  final String error;
  final String stackTrace;
  const ErrorText({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    log(error, name: "error text");
    return SafeArea(
      child: Column(
        children: [
          Text(
            error,
            textDirection: TextDirection.ltr,
          ),
          Text(
            stackTrace,
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}
