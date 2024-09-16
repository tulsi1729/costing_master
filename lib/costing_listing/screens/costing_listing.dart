import 'package:flutter/material.dart';

class CostingListing extends StatelessWidget {
  final String clientName;
  const CostingListing({super.key, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(clientName),
      ),
      body: const Text("name"),
    );
  }
}
