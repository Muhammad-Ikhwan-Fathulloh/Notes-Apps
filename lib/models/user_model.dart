/// User model matching https://6b07948d58419b87a4385752.mockapi.io/users.
class UserModel {
  const UserModel({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String name;
  final String avatar;
  final String password;
  final String createdAt;
  final String updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatar: (json['avatar'] ?? '-').toString(),
      password: (json['password'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatar': avatar,
      'password': password,
      'created_at': createdAt,
      'updated_at': updatedAt,
      if (userId.isNotEmpty) 'user_id': userId,
    };
  }
}
