/// User entity representing a user in the system
class User {
  final String id;
  final String userName;
  final String fullName;
  final String password;
  final String address;
  final String avatar;
  final String birthday; // Format: dd/mm/yyyy
  final String? fcmToken; // FCM token for push notifications

  const User({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.password,
    required this.address,
    required this.avatar,
    required this.birthday,
    this.fcmToken,
  });

  /// Create User from Firestore document
  factory User.fromJson(Map<String, dynamic> json, String id) {
    return User(
      id: id,
      userName: json['userName'] as String,
      fullName: json['fullName'] as String,
      password: json['password'] as String,
      address: json['address'] as String,
      avatar: json['avatar'] as String,
      birthday: json['birthday'] as String,
      fcmToken: json['fcmToken'] as String?,
    );
  }

  /// Convert User to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'fullName': fullName,
      'password': password,
      'address': address,
      'avatar': avatar,
      'birthday': birthday,
      'fcmToken': fcmToken,
    };
  }

  /// Create a copy of User with modified fields
  User copyWith({
    String? id,
    String? userName,
    String? fullName,
    String? password,
    String? address,
    String? avatar,
    String? birthday,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      birthday: birthday ?? this.birthday,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
