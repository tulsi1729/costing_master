import 'package:flutter/material.dart';

class Info extends StatefulWidget {
  final String clientName;
  const Info({super.key, required this.clientName});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  final sariNameController = TextEditingController();
  final sariNumberController = TextEditingController();
  String sariName = '';
  int sariNumber = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Text(
            widget.clientName,
            style: const TextStyle(fontSize: 32),
          ),
          Row(
            children: [
              Flexible(
                flex: 3,
                child: TextField(
                  controller: sariNameController,
                  onChanged: (sariName) {
                    sariNameController.text = sariName;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Sari Name',
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                flex: 1,
                child: TextField(
                  controller: sariNumberController,
                  onChanged: (sariNumber) {
                    sariNumberController.text = sariNumber;
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sari Number',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          const SizedBox(
            width: 350,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.red),
            ),
          ),
          ElevatedButton(onPressed: () {}, child: const Text("Select Image"))
        ],
      ),
    );
  }
}
