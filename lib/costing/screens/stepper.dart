import 'dart:developer';

import 'package:costing_master/screens/home_screen.dart';
import 'package:costing_master/screens/info.dart';
import 'package:costing_master/screens/preview.dart';
import 'package:flutter/material.dart';

class Stteper extends StatefulWidget {
  final String clientName;

  Stteper({super.key, required this.clientName});

  @override
  State<Stteper> createState() => _StteperState();
}

class _StteperState extends State<Stteper> {
  int currentStep = 0;
  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stteper"),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        steps: getSteps(),
        currentStep: currentStep,
        onStepContinue: () {
          final isLastStep = currentStep == getSteps().length - 1;
          if (isLastStep) {
            setState(
              () => isCompleted = true,
            );
            log("Complete");

            ///send data to server
          } else {
            setState(
              () => currentStep += 1,
            );
          }
        },
        onStepTapped: (int step) {
          setState(() {
            currentStep = step;
          });
        },
        onStepCancel: () {
          currentStep == 0 ? null : setState(() => currentStep -= 1);
        },
        controlsBuilder: (context, controlsDetails) {
          final isLastStep = currentStep == getSteps().length - 1;

          return Container(
            margin: const EdgeInsets.only(top: 50),
            child: Row(
              children: [
                  if(currentStep == 1 || currentStep == 0)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controlsDetails.onStepContinue;},
                    child: const Text("Next"),
                  )
                ),
                const SizedBox(
                  width: 12,
                ),
                if (currentStep != 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controlsDetails.onStepCancel,
                      child: const Text("Back"),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Step> getSteps() => [
        Step(
          state: currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 0,
          title: const Text("Info"),
          content: Info(clientName: widget.clientName),
        ),
        Step(
          state: currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1,
          title: const Text("Costing"),
          content: HomeScreen(
            clientName: widget.clientName,
          ),
        ),
        Step(
          state: currentStep > 2 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 2,
          title: const Text("Preview"),
          content: Preview(),
        ),
      ];
}
