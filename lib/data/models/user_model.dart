class UserModel {
  final String id;
  final String username;
  final String email;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] ?? '').toString();
    final username = (json['username'] ?? json['name'] ?? '').toString();

    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      username: username.isNotEmpty ? username : email.split('@').first,
      email: email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
    };
  }
}
