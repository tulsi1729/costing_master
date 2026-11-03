import 'package:costing_master/common/enums.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/model/sagadi_costing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// What a calculator screen is opened with. Compared by identity, so each
/// opened screen gets its own draft.
class DraftSeed {
  final String clientGuid;
  final String clientName;
  final String userUid;
  final Costing? existing;

  /// Starts a new costing pre-filled from this one ("duplicate").
  final Costing? copyOf;

  DraftSeed({
    required this.clientGuid,
    required this.clientName,
    required this.userUid,
    this.existing,
    this.copyOf,
  });
}

/// Immutable snapshot of the costing being edited.
class CostingDraft {
  final Costing costing;
  final String clientName;
  final bool isNew;
  final bool dirty;

  CostingDraft({
    required this.costing,
    required this.clientName,
    required this.isNew,
    this.dirty = false,
  });

  /// Computed once per snapshot and shared by every widget that selects from it.
  late final CostingBreakdown breakdown = CostingCalculator.compute(costing);

  bool get hasName => costing.sariName.trim().isNotEmpty;
  bool get hasPhoto =>
      costing.imageUrl.isNotEmpty && costing.imageUrl != 'null';
  bool get hasAmounts => breakdown.totalExpense > 0;
  bool get canSave => hasName && hasAmounts;

  DiamondCosting? diamond(PartType part, DiamondType type) =>
      costing.diamondCostingsMap?[part]?[type];

  SagadiCosting? sagadi(SagadiItemType type) =>
      costing.sagadiCostingsMap?[type];

  CostingDraft _with(Costing costing) => CostingDraft(
        costing: costing,
        clientName: clientName,
        isNew: isNew,
        dirty: true,
      );
}

class CostingDraftNotifier extends Notifier<CostingDraft> {
  CostingDraftNotifier(this.seed);

  final DraftSeed seed;

  @override
  CostingDraft build() {
    final existing = seed.existing;
    final copyOf = seed.copyOf;
    return CostingDraft(
      clientName: seed.clientName,
      isNew: existing == null,
      // A copy is unsaved from the start, so leaving asks to discard it.
      dirty: copyOf != null,
      costing: existing ??
          (copyOf == null
              ? _blank()
              : copyOf.copyWith(
                  guid: const Uuid().v4(),
                  createdBy: seed.userUid,
                  sariName: '${copyOf.sariName} (નકલ)',
                )),
    );
  }

  Costing _blank() => Costing(
        guid: const Uuid().v4(),
        createdBy: seed.userUid,
        clientGuid: seed.clientGuid,
        sariName: '',
        imageUrl: '',
        sheetBharvana: 0,
        lessFiting: 0,
        reniyaCutting: 0,
        fusing: 0,
        dieKapvana: 0,
        otherCost: 0,
        vatavPercentage: 0,
        profitPercentage: 0,
        diamondCostingsMap: {},
        sagadiCostingsMap: {},
        totalExpense: 0,
        totalChargesPlusVatavAmount: 0,
        totalChargesPlusVatavPlusProfit: 0,
      );

  Costing get _c => state.costing;

  void setSariName(String name) =>
      state = state._with(_c.copyWith(sariName: name));

  void setDesignNo(int? designNo) {
    // copyWith cannot clear a nullable field, so set it on the fresh copy.
    state = state._with(_c.copyWith()..designNo = designNo);
  }

  void setImageUrl(String url) =>
      state = state._with(_c.copyWith(imageUrl: url));

  /// [ratePer100] is what the user types; it is stored per single diamond.
  void setDiamond(
    PartType part,
    DiamondType type, {
    required int perPart,
    required double parts,
    required double ratePer100,
  }) {
    final all = {
      for (final e in (_c.diamondCostingsMap ?? const {}).entries)
        e.key: {...e.value},
    };
    final forPart = all.putIfAbsent(part, () => {});
    if (perPart == 0 && parts == 0 && ratePer100 == 0) {
      forPart.remove(type);
    } else {
      forPart[type] = DiamondCosting(
        diamondType: type,
        partType: part,
        diamondsPerPart: perPart,
        numbersOfPartsPerSari: parts,
        diamondRate: ratePer100 / diamondRateUnit,
      );
    }
    if (forPart.isEmpty) all.remove(part);
    state = state._with(_c.copyWith(diamondCostingsMap: all));
  }

  void setSagadi(SagadiItemType type,
      {required double count, required double rate}) {
    final all = {...?_c.sagadiCostingsMap};
    if (count == 0 && rate == 0) {
      all.remove(type);
    } else {
      all[type] =
          SagadiCosting(itemType: type, itemsCount: count, chargePerItem: rate);
    }
    state = state._with(_c.copyWith(sagadiCostingsMap: all));
  }

  void setFixed(FixedCharge charge, double value) {
    state = state._with(switch (charge) {
      FixedCharge.sheet => _c.copyWith(sheetBharvana: value),
      FixedCharge.lessFitting => _c.copyWith(lessFiting: value),
      FixedCharge.reniyaCutting => _c.copyWith(reniyaCutting: value),
      FixedCharge.fusing => _c.copyWith(fusing: value),
      FixedCharge.dieCutting => _c.copyWith(dieKapvana: value),
      FixedCharge.other => _c.copyWith(otherCost: value),
    });
  }

  void setVatav(double percentage) =>
      state = state._with(_c.copyWith(vatavPercentage: percentage));

  void setProfit(double percentage) =>
      state = state._with(_c.copyWith(profitPercentage: percentage));

  /// The costing as it should be stored, with totals from [CostingCalculator].
  Costing toSave() => CostingCalculator.withTotals(_c.copyWith(
        sariName: _c.sariName.trim(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));

  void markSaved() => state = CostingDraft(
        costing: _c,
        clientName: state.clientName,
        isNew: false,
      );
}

final costingDraftProvider = NotifierProvider.autoDispose
    .family<CostingDraftNotifier, CostingDraft, DraftSeed>(
        CostingDraftNotifier.new);

typedef DraftProvider = NotifierProvider<CostingDraftNotifier, CostingDraft>;
