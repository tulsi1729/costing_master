import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:costing_master/common/enums.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/model/sagadi_costing.dart';

class Costing {
  String guid;
  String createdBy;
  int? designNo;
  String clientGuid;
  String sariName;
  String imageUrl;
  double sheetBharvana;
  double lessFiting;
  double reniyaCutting;
  double fusing;
  double dieKapvana;
  double otherCost;
  double vatavPercentage;
  double profitPercentage;
  Map<DiamondType, DiamondCosting>? diamondCostingsMap;
  Map<SagadiItemType, SagadiCosting>? sagadiCostingsMap;

  Costing({
    required this.guid,
    required this.createdBy,
    this.designNo,
    required this.clientGuid,
    required this.sariName,
    required this.imageUrl,
    required this.sheetBharvana,
    required this.lessFiting,
    required this.reniyaCutting,
    required this.fusing,
    required this.dieKapvana,
    required this.otherCost,
    required this.vatavPercentage,
    required this.profitPercentage,
    required this.diamondCostingsMap,
    required this.sagadiCostingsMap,
  });

  Costing copyWith({
    String? guid,
    String? createdBy,
    int? designNo,
    String? clientGuid,
    String? sariName,
    String? imageUrl,
    double? sheetBharvana,
    double? lessFiting,
    double? reniyaCutting,
    double? fusing,
    double? dieKapvana,
    double? otherCost,
    double? vatavPercentage,
    double? profitPercentage,
    Map<DiamondType, DiamondCosting>? diamondCostingsMap,
    Map<SagadiItemType, SagadiCosting>? sagadiCostingsMap,
  }) {
    return Costing(
      guid: guid ?? this.guid,
      createdBy: createdBy ?? this.createdBy,
      designNo: designNo ?? this.designNo,
      clientGuid: clientGuid ?? this.clientGuid,
      sariName: sariName ?? this.sariName,
      imageUrl: imageUrl ?? this.imageUrl,
      sheetBharvana: sheetBharvana ?? this.sheetBharvana,
      lessFiting: lessFiting ?? this.lessFiting,
      reniyaCutting: reniyaCutting ?? this.reniyaCutting,
      fusing: fusing ?? this.fusing,
      dieKapvana: dieKapvana ?? this.dieKapvana,
      otherCost: otherCost ?? this.otherCost,
      vatavPercentage: vatavPercentage ?? this.vatavPercentage,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      diamondCostingsMap: diamondCostingsMap ?? this.diamondCostingsMap,
      sagadiCostingsMap: sagadiCostingsMap ?? this.sagadiCostingsMap,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'guid': guid,
      'createdBy': createdBy,
      'designNo': designNo,
      'clientGuid': clientGuid,
      'sariName': sariName,
      'imageUrl': imageUrl,
      'sheetBharvana': sheetBharvana,
      'lessFiting': lessFiting,
      'reniyaCutting': reniyaCutting,
      'fusing': fusing,
      'dieKapvana': dieKapvana,
      'otherCost': otherCost,
      'vatavPercentage': vatavPercentage,
      'profitPercentage': profitPercentage,
      'diamondCostingsMap': diamondCostingsMap == null
          ? null
          : _convertToStringDynamicDiamondMap(diamondCostingsMap!),
      'sagadiCostingsMap': sagadiCostingsMap == null
          ? null
          : _convertToStringDynamicSagadiMap(sagadiCostingsMap!),
    };
  }

  factory Costing.fromMap(Map<String, dynamic> map) {
    return Costing(
      guid: map['guid'] as String,
      createdBy: map['createdBy'] as String,
      designNo: map['designNo'] != null ? map['designNo'] as int : null,
      clientGuid: map['clientGuid'] as String,
      sariName: map['sariName'] as String,
      imageUrl: map['imageUrl'] as String,
      sheetBharvana: map['sheetBharvana'] as double,
      lessFiting: map['lessFiting'] as double,
      reniyaCutting: map['reniyaCutting'] as double,
      fusing: map['fusing'] as double,
      dieKapvana: map['dieKapvana'] as double,
      otherCost: map['otherCost'] as double,
      vatavPercentage: map['vatavPercentage'] as double,
      profitPercentage: map['profitPercentage'] as double,
      diamondCostingsMap: map['diamondCostingsMap'] != null
          ? _convertToDiamondCostingMap(map['diamondCostingsMap'])
          : null,
      sagadiCostingsMap: map['sagadiCostingsMap'] != null
          ? _convertToSagadiCostingMap(map['sagadiCostingsMap'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Costing.fromJson(String source) =>
      Costing.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Costing(guid: $guid, createdBy: $createdBy, designNo: $designNo, clientGuid: $clientGuid, sariName: $sariName, imageUrl: $imageUrl, sheetBharvana: $sheetBharvana, lessFiting: $lessFiting, reniyaCutting: $reniyaCutting, fusing: $fusing, dieKapvana: $dieKapvana, otherCost: $otherCost, vatavPercentage: $vatavPercentage, profitPercentage: $profitPercentage, diamondCostingsMap: $diamondCostingsMap, sagadiCostingsMap: $sagadiCostingsMap)';
  }

  @override
  bool operator ==(covariant Costing other) {
    if (identical(this, other)) return true;

    return other.guid == guid &&
        other.createdBy == createdBy &&
        other.designNo == designNo &&
        other.clientGuid == clientGuid &&
        other.sariName == sariName &&
        other.imageUrl == imageUrl &&
        other.sheetBharvana == sheetBharvana &&
        other.lessFiting == lessFiting &&
        other.reniyaCutting == reniyaCutting &&
        other.fusing == fusing &&
        other.dieKapvana == dieKapvana &&
        other.otherCost == otherCost &&
        other.vatavPercentage == vatavPercentage &&
        other.profitPercentage == profitPercentage &&
        mapEquals(other.diamondCostingsMap, diamondCostingsMap) &&
        mapEquals(other.sagadiCostingsMap, sagadiCostingsMap);
  }

  @override
  int get hashCode {
    return guid.hashCode ^
        createdBy.hashCode ^
        designNo.hashCode ^
        clientGuid.hashCode ^
        sariName.hashCode ^
        imageUrl.hashCode ^
        sheetBharvana.hashCode ^
        lessFiting.hashCode ^
        reniyaCutting.hashCode ^
        fusing.hashCode ^
        dieKapvana.hashCode ^
        otherCost.hashCode ^
        vatavPercentage.hashCode ^
        profitPercentage.hashCode ^
        diamondCostingsMap.hashCode ^
        sagadiCostingsMap.hashCode;
  }

  static Map<SagadiItemType, SagadiCosting> _convertToSagadiCostingMap(
      Map<String, dynamic> dynamicMap) {
    Map<SagadiItemType, SagadiCosting> sagadiCostingMap = {};

    dynamicMap.forEach((key, value) {
      SagadiCosting costing = SagadiCosting.fromMap(value);
      sagadiCostingMap[costing.itemType] = costing;
    });

    return sagadiCostingMap;
  }

  static Map<DiamondType, DiamondCosting> _convertToDiamondCostingMap(
      Map<String, dynamic> dynamicMap) {
    Map<DiamondType, DiamondCosting> diamondCostingMap = {};

    dynamicMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        DiamondCosting costing = DiamondCosting.fromMap(value);
        diamondCostingMap[costing.diamondType] = costing;
      }
    });

    return diamondCostingMap;
  }

  static Map<String, dynamic> _convertToStringDynamicDiamondMap(
      Map<DiamondType, DiamondCosting> dynamicMap) {
    Map<String, dynamic> diamondCostingMap = {};

    dynamicMap.forEach((key, value) {
      dynamic costing = value.toMap();
      diamondCostingMap[value.diamondType.toString()] = costing;
    });

    return diamondCostingMap;
  }

  static Map<String, dynamic> _convertToStringDynamicSagadiMap(
      Map<SagadiItemType, SagadiCosting> dynamicMap) {
    Map<String, dynamic> sagadiCostingMap = {};

    dynamicMap.forEach((key, value) {
        dynamic costing = value.toMap();
        sagadiCostingMap[value.itemType.toString()] = costing;
    });

    return sagadiCostingMap;
  }
}
