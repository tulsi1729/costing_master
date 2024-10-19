import 'package:costing_master/costings/notifier/costing_notifier.dart';
import 'package:costing_master/costings/screens/costing_listing.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/costings/screens/costing_listing_tile.dart';
import 'package:costing_master/loading/loading_notifier.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/info_model.dart';
import 'package:costing_master/model/preview_model.dart';
import 'package:costing_master/costings/costing_stepper/info_screen.dart';
import 'package:costing_master/costings/costing_stepper/preview_screen.dart';
import 'package:costing_master/costings/costing_stepper/costing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class CostingStepper extends ConsumerStatefulWidget {
  final String clientName;
  final String clientGuid;
  final Costing? costing;

  const CostingStepper({
    super.key,
    required this.clientName,
    required this.clientGuid,
    this.costing,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StepperState();
}

class _StepperState extends ConsumerState<CostingStepper> {
  GlobalKey<InfoState> globalKey = GlobalKey();
  GlobalKey<CostingScreenState> costingScreenState = GlobalKey();

  int currentStep = 0;
  bool isCompleted = false;
  InfoModel? info;
  Costing? costing;
  late String costingGUID;
  bool isNavigationDisabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.costing == null) {
      costingGUID = const Uuid().v4();
    } else {
      costingGUID = widget.costing!.guid;

      info = InfoModel(
        clientName: widget.clientName,
        sariName: widget.costing!.sariName,
        imageUrl: widget.costing!.imageUrl,
        designNo: widget.costing!.designNo,
      );
      costing = widget.costing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stepper"),
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
                        controlsDetails.onStepCancel!();
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
                    ),
                  ),
                if (currentStep == 1)
                  Expanded(
                      child: ElevatedButton(
                    onPressed: isNavigationDisabled
                        ? null
                        : () async {
                            ref.read(loadingProvider.notifier).set(true);
                            if (costingScreenState.currentState == null) {
                            } else if (costingScreenState.currentState !=
                                null) {
                              await costingScreenState.currentState!
                                  .saveCostingModelToParent();

                              await ref
                                  .read(costingProvider.notifier)
                                  .createCosting(costing!);
                              await ref
                                  .read(costingsProvider.notifier)
                                  .refresh();
                            }
                            controlsDetails.onStepContinue!();
                            ref.read(loadingProvider.notifier).set(false);
                          },
                    child: const Text("Next "),
                  )),
                if (currentStep == 2)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CostingListing(
                              clientName: widget.clientName,
                              clientGuid: widget.clientGuid,
                            ),
                          ),
                        );
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
            },
            key: globalKey,
            clientName: widget.clientName,
            infoUpdate: (InfoModel info) {
              this.info = info;
            },
            info: info,
          ),
        ),
        Step(
          state: currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1,
          title: const Text("Costing"),
          content: info == null
              ? Container()
              : CostingScreen(
                  key: costingScreenState,
                  clientName: widget.clientName,
                  clientGuid: widget.clientGuid,
                  costingGUID: costingGUID,
                  info: info!,
                  costingUpdate: (Costing costing) {
                    this.costing = costing;
                  },
                  costing: costing,
                ),
        ),
        Step(
          state: currentStep > 2 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 2,
          title: const Text("Preview"),
          content: costing == null
              ? Container()
              : Preview(
                  previewModel: PreviewModel(
                      costing: costing!, clientName: widget.clientName),
                  costing: costing,
                  clientName: widget.clientName),
        ),
      ];
}
