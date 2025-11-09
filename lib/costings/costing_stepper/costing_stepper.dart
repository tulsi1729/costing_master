import 'package:costing_master/costings/notifier/costing_notifier.dart';
import 'package:costing_master/costings/screens/costing_listing.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
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
  bool isInfoFormValid = false;
  bool isCostingFormValid = false;

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
      isInfoFormValid = widget.costing!.sariName.isNotEmpty && 
                       widget.costing!.imageUrl.isNotEmpty;
      isCostingFormValid = widget.costing!.totalExpense > 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Costing",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade400,
                Colors.deepPurple.shade600,
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade300,
                  Colors.deepPurple.shade500,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stepper(
              type: StepperType.horizontal,
              steps: getSteps(),
              currentStep: currentStep,
              physics: const AlwaysScrollableScrollPhysics(),
        onStepContinue: () {
          final isLastStep = currentStep == getSteps().length - 1;

          if (isLastStep) {
            setState(
              () => isCompleted = true,
            );

          } else {
            setState(
              () => currentStep += 1,
            );
          }
        },
        onStepTapped: (int step) {
          if (isNavigationDisabled) return;
          if (step == currentStep) {
            return;
          }
          if (step < currentStep) {
            setState(() {
              currentStep = step;
            });
            return;
          }
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.block,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please use the Next button to proceed to the next step.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        },
        onStepCancel: () {
          currentStep == 0 ? null : setState(() => currentStep -= 1);
        },
        controlsBuilder: (context, controlsDetails) {
          currentStep == getSteps().length - 1;

          return Container(
            margin: const EdgeInsets.only(top: 50, bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (currentStep != 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        controlsDetails.onStepCancel!();
                      },
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text("Back"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 12,
                ),
                if (currentStep == 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isNavigationDisabled || !isInfoFormValid)
                          ? null
                          : () {
                              if (globalKey.currentState != null) {
                                final isValid = globalKey.currentState!
                                    .validateAndSave();
                                if (!isValid) {
                                  // Hide any existing snackbar first
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  // Show error snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Please fill in all required fields before continuing.',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }
                              }
                              controlsDetails.onStepContinue!();
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isInfoFormValid ? "Next" : "Fill Required Fields",
                            style: TextStyle(
                              fontSize: isInfoFormValid ? 16 : 13,
                            ),
                          ),
                          if (isInfoFormValid) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (currentStep == 1)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isNavigationDisabled || !isCostingFormValid)
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
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isCostingFormValid ? "Next" : "Add Costing Data",
                            style: TextStyle(
                              fontSize: isCostingFormValid ? 16 : 13,
                            ),
                          ),
                          if (isCostingFormValid) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (currentStep == 2)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CostingListing(
                              clientName: widget.clientName,
                              clientGuid: widget.clientGuid,
                            ),
                          ),
                          (route) => false
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 18,color: Colors.white,),
                          SizedBox(width: 8),
                          Text("Done", style: TextStyle(color: Colors.white),),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  List<Step> getSteps() => [
        Step(
          state: currentStep > 0 
              ? (isInfoFormValid ? StepState.complete : StepState.error)
              : StepState.indexed,
          isActive: currentStep == 0,
          title: const Text(
            "Info",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: InfoScreen(
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
            setIsFormValid: (bool isValid) {
              setState(() {
                isInfoFormValid = isValid;
              });
            },
            ),
          ),
        ),
        Step(
          state: currentStep > 1
              ? (isCostingFormValid ? StepState.complete : StepState.error)
              : (currentStep == 1 
                  ? StepState.indexed 
                  : StepState.disabled),
          isActive: currentStep == 1,
          title: const Text(
            "Costing",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: info == null
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
                  setIsFormValid: (bool isValid) {
                    setState(() {
                      isCostingFormValid = isValid;
                    });
                  },
                ),
          ),
        ),
        Step(
          state: currentStep == 2
              ? StepState.indexed
              : (currentStep > 2
                  ? StepState.complete
                  : StepState.disabled),
          isActive: currentStep == 2,
          title: const Text(
            "Preview",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: costing == null
                ? Container()
                : Preview(
                  previewModel: PreviewModel(
                      costing: costing!, clientName: widget.clientName),
                  costing: costing,
                  clientName: widget.clientName,
                   isFromStepper: true,),
          ),
        ),
      ];
}
