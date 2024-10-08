import 'package:uuid/uuid.dart';

class Client {
  final String name;
  final String guid;
  final String createdBy;

  Client({
    String? guid,
    required this.name,
    required this.createdBy,
  }) : guid = guid ?? const Uuid().v4();

  Client copyWith({
    String? name,
    String? guid,
    String? createdBy,
  }) {
    return Client(
      name: name ?? this.name,
      guid: guid ?? this.guid,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'guid': guid,
      'createdBy': createdBy,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      name: map['name'] as String,
      guid: map['guid'] as String,
      createdBy: map['createdBy'] as String,
    );
  }

  @override
  String toString() => 'Client(name: $name, guid: $guid, createdBy: $createdBy)';

  @override
  bool operator ==(covariant Client other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.guid == guid &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode => name.hashCode ^ guid.hashCode ^ createdBy.hashCode;
}
