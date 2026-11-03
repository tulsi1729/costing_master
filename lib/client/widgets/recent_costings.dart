import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:flutter/material.dart';

/// A compact horizontal strip of the latest costings across all clients.
class RecentCostings extends StatelessWidget {
  final List<Costing> costings;
  final ValueChanged<Costing> onOpen;

  const RecentCostings(
      {super.key, required this.costings, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: costings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final costing = costings[index];
          return _RecentCard(costing: costing, onTap: () => onOpen(costing));
        },
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final Costing costing;
  final VoidCallback onTap;

  const _RecentCard({required this.costing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = CostingCalculator.compute(costing).grandTotal;
    return SizedBox(
      width: 104,
      child: Material(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: NetworkThumb(url: costing.imageUrl)),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      costing.sariName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelLarge,
                    ),
                    Text(
                      formatRupees(price, decimals: 0),
                      maxLines: 1,
                      style: context.text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
