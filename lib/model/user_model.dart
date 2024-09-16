class UserModel {
  final String name;
  final String uid;

  UserModel({
    required this.name,
    required this.uid,
  });

  UserModel copyWith({
    String? name,
    String? uid,
  }) {
    return UserModel(
      name: name ?? this.name,
      uid: uid ?? this.uid,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'uid': uid,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] as String,
      uid: map['uid'] as String,
    );
  }

  @override
  String toString() => 'UserModel(name: $name, uid: $uid)';

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.name == name && other.uid == uid;
  }

  @override
  int get hashCode => name.hashCode ^ uid.hashCode;
}
