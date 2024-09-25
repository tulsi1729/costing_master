import 'dart:developer';

import 'package:costing_master/model/info_model.dart';
import 'package:costing_master/screens/home_screen.dart';
import 'package:costing_master/screens/info_screen.dart';
import 'package:costing_master/screens/preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingSteeper extends ConsumerStatefulWidget {
  final String clientName;

  const CostingSteeper({super.key, required this.clientName});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SteeperState();
}

class _SteeperState extends ConsumerState<CostingSteeper> {
  GlobalKey<InfoState> globalKey = GlobalKey();

  int currentStep = 0;
  bool isCompleted = false; // TODO: remove
  InfoModel? info;
  bool isNavigationDisabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Steeper"),
        actions: [
          ElevatedButton(
            onPressed: () {
              log('info is $info');
            },
            child: const Text("check info"),
          )
        ],
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

            ///send data to server
          } else {
            setState(
              () => currentStep += 1,
            );
          }
        },
        onStepTapped: (int step) {
          if (isNavigationDisabled) return;
          setState(() {
            currentStep = step;
          });
        },
        onStepCancel: () {
          currentStep == 0 ? null : setState(() => currentStep -= 1);
        },
        controlsBuilder: (context, controlsDetails) {
          currentStep == getSteps().length - 1;

          return Container(
            margin: const EdgeInsets.only(top: 50),
            child: Row(
              children: [
                if (currentStep != 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controlsDetails.onStepCancel;
                        log("back");
                      },
                      child: const Text("Back"),
                    ),
                  ),
                const SizedBox(
                  width: 12,
                ),
                if (currentStep == 0)
                  Expanded(
                      child: ElevatedButton(
                    onPressed: isNavigationDisabled
                        ? null
                        : () {
                            if (globalKey.currentState != null) {
                              globalKey.currentState!.saveInfoModelToParent();
                            }

                            controlsDetails.onStepContinue!();
                          },
                    child: const Text("Next"),
                  )),
                if (currentStep == 1)
                  Expanded(
                      child: ElevatedButton(
                    onPressed: isNavigationDisabled
                        ? null
                        : () {
                            log("costing");

                            if (globalKey.currentState != null) {
                              globalKey.currentState!.saveInfoModelToParent();
                            }
                            controlsDetails.onStepContinue!();
                          },
                    child: const Text("Next"),
                  )),
                if (currentStep == 2)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controlsDetails.onStepContinue!();
                        log("    2   ");
                      },
                      child: const Text("Done"),
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
          content: InfoScreen(
            setIsNavigationDisabled: (bool isNavigationDisabled) {
              setState(() {
                this.isNavigationDisabled = isNavigationDisabled;
              });
              log("info after  $isNavigationDisabled");
            },
            key: globalKey,
            clientName: widget.clientName,
            infoUpdate: (InfoModel info) {
              this.info = info;
              log('info saved : $info');
            },
          ),
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
          content: Preview(
            info: info,
          ),
        ),
      ];
}
