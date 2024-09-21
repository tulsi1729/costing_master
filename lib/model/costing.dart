// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/model/sagadi_costing.dart';
import 'package:flutter/foundation.dart';

import 'package:costing_master/model/diamond_costing.dart';

class Costing {
  String createdBy;
  int? designNo;
  String clientUid;
  String sariName;
  String imageUrl;
  double sheetBharvana;
  double lessFiting;
  double reniyaCutting;
  double fusing;
  double dieKapvana;
  double otherCost;
  double totalCost;
  double vatavPercentage;
  double profitPercentage;
  List<DiamondCosting> diamondCostings;
  List<SagadiCosting> sagadiCostings;

  Costing({
    required this.createdBy,
    this.designNo,
    required this.clientUid,
    required this.sariName,
    required this.imageUrl,
    required this.sheetBharvana,
    required this.lessFiting,
    required this.reniyaCutting,
    required this.fusing,
    required this.dieKapvana,
    required this.otherCost,
    required this.totalCost,
    required this.vatavPercentage,
    required this.profitPercentage,
    required this.diamondCostings,
    required this.sagadiCostings,
  });

  Costing copyWith({
    String? createdBy,
    int? designNo,
    String? clientUid,
    String? sariName,
    String? imageUrl,
    double? sheetBharvana,
    double? lessFiting,
    double? reniyaCutting,
    double? fusing,
    double? dieKapvana,
    double? otherCost,
    double? totalCost,
    double? vatavPercentage,
    double? profitPercentage,
    List<DiamondCosting>? diamondCostings,
    List<SagadiCosting>? sagadiCostings,
  }) {
    return Costing(
      createdBy: createdBy ?? this.createdBy,
      designNo: designNo ?? this.designNo,
      clientUid: clientUid ?? this.clientUid,
      sariName: sariName ?? this.sariName,
      imageUrl: imageUrl ?? this.imageUrl,
      sheetBharvana: sheetBharvana ?? this.sheetBharvana,
      lessFiting: lessFiting ?? this.lessFiting,
      reniyaCutting: reniyaCutting ?? this.reniyaCutting,
      fusing: fusing ?? this.fusing,
      dieKapvana: dieKapvana ?? this.dieKapvana,
      otherCost: otherCost ?? this.otherCost,
      totalCost: totalCost ?? this.totalCost,
      vatavPercentage: vatavPercentage ?? this.vatavPercentage,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      diamondCostings: diamondCostings ?? this.diamondCostings,
      sagadiCostings: sagadiCostings ?? this.sagadiCostings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirebaseConstants.createdBy: createdBy,
      FirebaseConstants.designNo: designNo,
      FirebaseConstants.clientUid: clientUid,
      FirebaseConstants.sariName: sariName,
      FirebaseConstants.imageUrl: imageUrl,
      FirebaseConstants.sheetBharvana: sheetBharvana,
      FirebaseConstants.lessFiting: lessFiting,
      FirebaseConstants.reniyaCutting: reniyaCutting,
      FirebaseConstants.fusing: fusing,
      FirebaseConstants.dieKapvana: dieKapvana,
      FirebaseConstants.otherCost: otherCost,
      FirebaseConstants.totalCost: totalCost,
      FirebaseConstants.vatavPercentage: vatavPercentage,
      FirebaseConstants.profitPercentage: profitPercentage,
      FirebaseConstants.diamondCostings: diamondCostings.map((x) => x.toMap()).toList(),
      FirebaseConstants.sagadiCostings: sagadiCostings.map((x) => x.toMap()).toList(),
    };
  }

  factory Costing.fromMap(Map<String, dynamic> map) {
    return Costing(
      createdBy: map['createdBy'] as String,
      designNo: map['designNo'] != null ? map['designNo'] as int : null,
      clientUid: map['clientUid'] as String,
      sariName: map['sariName'] as String,
      imageUrl: map['imageUrl'] as String,
      sheetBharvana: map['sheetBharvana'] as double,
      lessFiting: map['lessFiting'] as double,
      reniyaCutting: map['reniyaCutting'] as double,
      fusing: map['fusing'] as double,
      dieKapvana: map['dieKapvana'] as double,
      otherCost: map['otherCost'] as double,
      totalCost: map['totalCost'] as double,
      vatavPercentage: map['vatavPercentage'] as double,
      profitPercentage: map['profitPercentage'] as double,
      diamondCostings: List<DiamondCosting>.from((map['diamondCostings'] as List<int>).map<DiamondCosting>((x) => DiamondCosting.fromMap(x as Map<String,dynamic>),),),
      sagadiCostings: List<SagadiCosting>.from((map['sagadiCostings'] as List<int>).map<SagadiCosting>((x) => SagadiCosting.fromMap(x as Map<String,dynamic>),),),
    );
  }

  String toJson() => json.encode(toMap());

  factory Costing.fromJson(String source) => Costing.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Costing(createdBy: $createdBy, designNo: $designNo, clientUid: $clientUid, sariName: $sariName, imageUrl: $imageUrl, sheetBharvana: $sheetBharvana, lessFiting: $lessFiting, reniyaCutting: $reniyaCutting, fusing: $fusing, dieKapvana: $dieKapvana, otherCost: $otherCost, totalCost: $totalCost, vatavPercentage: $vatavPercentage, profitPercentage: $profitPercentage, diamondCostings: $diamondCostings, sagadiCostings: $sagadiCostings)';
  }

  @override
  bool operator ==(covariant Costing other) {
    if (identical(this, other)) return true;
  
    return 
      other.createdBy == createdBy &&
      other.designNo == designNo &&
      other.clientUid == clientUid &&
      other.sariName == sariName &&
      other.imageUrl == imageUrl &&
      other.sheetBharvana == sheetBharvana &&
      other.lessFiting == lessFiting &&
      other.reniyaCutting == reniyaCutting &&
      other.fusing == fusing &&
      other.dieKapvana == dieKapvana &&
      other.otherCost == otherCost &&
      other.totalCost == totalCost &&
      other.vatavPercentage == vatavPercentage &&
      other.profitPercentage == profitPercentage &&
      listEquals(other.diamondCostings, diamondCostings) &&
      listEquals(other.sagadiCostings, sagadiCostings);
  }

  @override
  int get hashCode {
    return createdBy.hashCode ^
      designNo.hashCode ^
      clientUid.hashCode ^
      sariName.hashCode ^
      imageUrl.hashCode ^
      sheetBharvana.hashCode ^
      lessFiting.hashCode ^
      reniyaCutting.hashCode ^
      fusing.hashCode ^
      dieKapvana.hashCode ^
      otherCost.hashCode ^
      totalCost.hashCode ^
      vatavPercentage.hashCode ^
      profitPercentage.hashCode ^
      diamondCostings.hashCode ^
      sagadiCostings.hashCode;
  }
}
