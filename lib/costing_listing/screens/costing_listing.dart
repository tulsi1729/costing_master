import 'package:costing_master/costing/screens/costing_steeper.dart';
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
      body: const Text("Costing Listing "),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CostingSteeper(
                clientName: clientName,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
