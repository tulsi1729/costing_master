import 'package:costing_master/common/extension/async_value.dart';
import 'package:costing_master/costing/notifier/costing_notifier.dart';
import 'package:costing_master/costings/screens/costing_stepper.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingListing extends ConsumerStatefulWidget {
  final String clientName;
  final String clientUid;
  const CostingListing(
      {super.key, required this.clientName, required this.clientUid});

  @override
  ConsumerState<CostingListing> createState() => _CostingListingState();
}

class _CostingListingState extends ConsumerState<CostingListing> {
  late Costing costing;

  @override
  Widget build(BuildContext context) {
    return ref.watch(costingProvider).whenWidget(
          (costings) => Scaffold(
            appBar: AppBar(
              title: Text(widget.clientName),
            ),
            body: ListView.builder(
              itemCount: costings.length,
              itemBuilder: (context, index) {
                final costing = costings[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CostingStepper(
                          clientName: widget.clientName,
                          clientUid: widget.clientUid,
                          costing: costing,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(costing.sariName),
                      // subtitle: Column(
                      //   children: [
                      //     Text(
                      //         "Diamond Costing ${costing.diamondCostings.toString()}"),
                      //     Text(
                      //         "Sagadi Costing ${costing.sagadiCostings.toString()}"),
                      //     Text(
                      //         "Sheet Bharvana ${costing.sheetBharvana.toString()}"),
                      //     Text("Less Fiting ${costing.lessFiting.toString()}"),
                      //     Text(
                      //         "Reniya cutting ${costing.reniyaCutting.toString()}"),
                      //     Text("fusing ${costing.fusing.toString()}"),
                      //     Text("Die kapvana ${costing.dieKapvana.toString()}"),
                      //     Text("Other Cost  ${costing.otherCost.toString()}"),
                      //     Text("vatav  ${costing.vatavPercentage.toString()}"),
                      //     Text("profit ${costing.profitPercentage.toString()}"),
                      // ],
                      // ),
                    ),
                  ),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CostingStepper(
                      clientName: widget.clientName,
                      clientUid: widget.clientUid,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
  }
}
