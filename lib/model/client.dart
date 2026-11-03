import 'package:uuid/uuid.dart';

class Client {
  final String name;
  final String guid;
  final String createdBy;

  /// Optional contact details; empty when not given.
  final String phone;
  final String city;

  /// Last edit time in epoch milliseconds; null for clients never edited.
  final int? updatedAt;

  Client({
    String? guid,
    required this.name,
    required this.createdBy,
    this.phone = '',
    this.city = '',
    this.updatedAt,
  }) : guid = guid ?? const Uuid().v4();

  Client copyWith({
    String? name,
    String? phone,
    String? city,
    int? updatedAt,
  }) {
    return Client(
      guid: guid,
      createdBy: createdBy,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'guid': guid,
      'createdBy': createdBy,
      'phone': phone,
      'city': city,
      'updatedAt': updatedAt,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      name: map['name'] as String,
      guid: map['guid'] as String,
      createdBy: map['createdBy'] as String,
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String? ?? '',
      updatedAt: (map['updatedAt'] as num?)?.toInt(),
    );
  }

  @override
  String toString() => 'Client(name: $name, guid: $guid)';

  @override
  bool operator ==(covariant Client other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.guid == guid &&
        other.createdBy == createdBy &&
        other.phone == phone &&
        other.city == city &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(name, guid, createdBy, phone, city, updatedAt);
}
