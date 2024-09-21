// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:costing_master/common/enums.dart';

class SagadiCosting {
    SagadiItemType itemType;
    double  itemsCount;
    double chargePerItem;
  SagadiCosting({
    required this.itemType,
    required this.itemsCount,
    required this.chargePerItem,
  });

  SagadiCosting copyWith({
    SagadiItemType? itemType,
    double? itemsCount,
    double? chargePerItem,
  }) {
    return SagadiCosting(
      itemType: itemType ?? this.itemType,
      itemsCount: itemsCount ?? this.itemsCount,
      chargePerItem: chargePerItem ?? this.chargePerItem,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'itemType': itemType.toString(),
      'itemsCount': itemsCount,
      'chargePerItem': chargePerItem,
    };
  }

  factory SagadiCosting.fromMap(Map<String, dynamic> map) {
    return SagadiCosting(
      itemType: {
        SagadiItemType.buta.toString() : SagadiItemType.buta,//todo understand this
        SagadiItemType.less.toString() : SagadiItemType.less,
        SagadiItemType.valiya.toString() : SagadiItemType.valiya,
      }[(map['itemType'] as String)]!,
      itemsCount: map['itemsCount'] as double,
      chargePerItem: map['chargePerItem'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory SagadiCosting.fromJson(String source) => SagadiCosting.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'SagadiCostind(itemType: $itemType, itemsCount: $itemsCount, chargePerItem: $chargePerItem)';

  @override
  bool operator ==(covariant SagadiCosting other) {
    if (identical(this, other)) return true;
    return
      other.itemType == itemType &&
      other.itemsCount == itemsCount &&
      other.chargePerItem == chargePerItem;
  }

  @override
  int get hashCode => itemType.hashCode ^ itemsCount.hashCode ^ chargePerItem.hashCode;
  }