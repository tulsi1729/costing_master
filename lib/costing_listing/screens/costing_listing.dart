
import 'package:costing_master/costing/screens/stepper.dart';
import 'package:flutter/material.dart';

class CostingListing extends StatelessWidget {
  final String clientName;
   CostingListing({super.key, required this.clientName});

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
              builder: (context) => Stteper(clientName: clientName,),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
 
}
