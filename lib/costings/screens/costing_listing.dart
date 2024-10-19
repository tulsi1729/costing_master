import 'package:costing_master/common/extension/async_value.dart';
import 'package:costing_master/costings/screens/costing_listing_tile.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/costings/costing_stepper/costing_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingListing extends ConsumerStatefulWidget {
  final String clientName;
  final String clientGuid;

  const CostingListing(
      {super.key, required this.clientName, required this.clientGuid});

  @override
  ConsumerState<CostingListing> createState() => _CostingListingState();
}

class _CostingListingState extends ConsumerState<CostingListing> {
  @override
  Widget build(BuildContext context) {
    return ref.watch(costingsProvider).whenWidget(
          (costings) => Scaffold(
            appBar: AppBar(
              title: Text(widget.clientName),
            ),
            body: ListView.builder(
              itemCount: costings.length,
              itemBuilder: (context, index) {
                final costing = costings[index];
                return CostingListingTile(costing);
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CostingStepper(
                      clientName: widget.clientName,
                      clientGuid: widget.clientGuid,
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
