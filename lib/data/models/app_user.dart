import 'package:equatable/equatable.dart';

enum UserRole {
  owner,
  staff;

  static UserRole parse(String? value) =>
      value == UserRole.owner.name ? UserRole.owner : UserRole.staff;
}

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String shopId;
  final String shopName;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.shopId,
    this.shopName = '',
  });

  bool get isOwner => role == UserRole.owner;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'shop_id': shopId,
        'shop_name': shopName,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: UserRole.parse(json['role'] as String?),
        shopId: '${json['shop_id'] ?? ''}',
        shopName: json['shop_name'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, name, email, role, shopId, shopName];
}
