import 'dart:convert';

import 'package:costing_master/common/enums.dart';

class DiamondCosting {
  DiamondType diamondType;
  double diamondRate;
  int diamondsPerPart;
  double numbersOfPartsPerSari;
  PartType partType;
  DiamondCosting({
    required this.diamondType,
    required this.diamondRate,
    required this.diamondsPerPart,
    required this.numbersOfPartsPerSari,
    required this.partType,
  });

  DiamondCosting copyWith({
    DiamondType? diamondType,
    double? diamondRate,
    int? diamondsPerPart,
    double? numbersOfPartsPerSari,
    PartType? partType,
  }) {
    return DiamondCosting(
      diamondType: diamondType ?? this.diamondType,
      diamondRate: diamondRate ?? this.diamondRate,
      diamondsPerPart: diamondsPerPart ?? this.diamondsPerPart,
      numbersOfPartsPerSari:
          numbersOfPartsPerSari ?? this.numbersOfPartsPerSari,
      partType: partType ?? this.partType,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'diamondType': diamondType.name,
      'diamondRate': diamondRate,
      'diamondsPerPart': diamondsPerPart,
      'numbersOfPartsPerSari': numbersOfPartsPerSari,
      'partType': partType.name,
    };
  }

  factory DiamondCosting.fromMap(Map<String, dynamic> map) {
    return DiamondCosting(
      diamondType: {
        DiamondType.dmc.name: DiamondType.dmc,
        DiamondType.shadow.name: DiamondType.shadow,
        DiamondType.color.name: DiamondType.color,
        DiamondType.jarkan.name: DiamondType.jarkan,
      }[(map['diamondType'] as String)]!,
      diamondRate: map['diamondRate'] as double,
      diamondsPerPart: map['diamondsPerPart'] as int,
      numbersOfPartsPerSari: map['numbersOfPartsPerSari'] as double,
      partType: {
        PartType.patti.name: PartType.patti,
        PartType.buta.name: PartType.buta,
      }[(map['partType'] as String)]!,
    );
  }

  String toJson() => json.encode(toMap());

  factory DiamondCosting.fromJson(String source) =>
      DiamondCosting.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DiamondCosting(diamondType: $diamondType, diamondRate: $diamondRate, diamondsPerPart: $diamondsPerPart, numbersOfPartsPerSari: $numbersOfPartsPerSari, partType: $partType)';
  }

  @override
  bool operator ==(covariant DiamondCosting other) {
    if (identical(this, other)) return true;

    return other.diamondType == diamondType &&
        other.diamondRate == diamondRate &&
        other.diamondsPerPart == diamondsPerPart &&
        other.numbersOfPartsPerSari == numbersOfPartsPerSari &&
        other.partType == partType;
  }

  @override
  int get hashCode {
    return diamondType.hashCode ^
        diamondRate.hashCode ^
        diamondsPerPart.hashCode ^
        numbersOfPartsPerSari.hashCode ^
        partType.hashCode;
  }
}
