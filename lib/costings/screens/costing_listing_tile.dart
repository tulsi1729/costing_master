import 'package:costing_master/costings/notifier/selected_client_notifier.dart';
import 'package:costing_master/costings/costing_stepper/separate_preview.dart';
import 'package:costing_master/costings/costing_stepper/costing_stepper.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/preview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingListingTile extends StatelessWidget {
  final Costing costing;
  const CostingListingTile(
    this.costing, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Consumer(
              builder: (_, ref, __) => CostingStepper(
                clientName: ref.read(selectedClientProvider)!.name,
                clientGuid: costing.clientGuid,
                costing: costing,
              ),
            ),
          ),
        );
        // Navigator.pop(context);
      },
      child: Card(
        child: ListTile(
          title: Text(costing.sariName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Consumer(
                          builder: (_, ref, __) => SeparatePreview(
                                previewModel: PreviewModel(
                                  costing: costing,
                                  clientName:
                                      ref.read(selectedClientProvider)!.name,
                                ),
                                costing: costing,
                                clientName:
                                    ref.read(selectedClientProvider)!.name,
                              )),
                    ),
                  );
                },
                icon: const Icon(Icons.preview),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Consumer(
                        builder: (_, ref, __) => CostingStepper(
                          clientName:
                              ref.read(selectedClientProvider)?.name ?? "",
                          clientGuid: costing.clientGuid,
                          costing: costing,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
              )
            ],
          ),
        ),
      ),
    );
  }
}
