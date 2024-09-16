import 'package:uuid/uuid.dart';

class Client {
  final String name;
  final String uid;
  final String createdBy;

  Client({
    String? uid,
    required this.name,
    required this.createdBy,
  }) : uid = uid ?? const Uuid().v4();

  Client copyWith({
    String? name,
    String? uid,
    String? createdBy,
  }) {
    return Client(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'uid': uid,
      'createdBy': createdBy,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      name: map['name'] as String,
      uid: map['uid'] as String,
      createdBy: map['createdBy'] as String,
    );
  }

  @override
  String toString() => 'Client(name: $name, uid: $uid, createdBy: $createdBy)';

  @override
  bool operator ==(covariant Client other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.uid == uid &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode => name.hashCode ^ uid.hashCode ^ createdBy.hashCode;
}
