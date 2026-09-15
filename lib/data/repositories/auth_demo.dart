import 'package:uuid/uuid.dart';
import '../../logic/domain/validators.dart';
import '../models/app_user.dart';
import 'auth_repo.dart';
import 'demo_data.dart';
import 'repo_exceptions.dart';

/// Offline demo accounts, used when no backend is configured.
class AuthDemo implements AuthRepo {
  final List<AppUser> _users = [...DemoData.users];
  final Map<String, String> _passwords = {
    for (final user in DemoData.users) user.email: DemoData.password,
  };
  final AppUser? Function() currentUser;

  AuthDemo({required this.currentUser});

  @override
  Future<Session> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final normalized = email.trim().toLowerCase();
    final user = _users.where((u) => u.email == normalized).firstOrNull;
    if (user == null || _passwords[normalized] != password) {
      throw const InvalidCredentialsException();
    }
    return Session(user, 'demo-token-${user.id}');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<List<AppUser>> getStaff() async => List.unmodifiable(_users);

  @override
  Future<AppUser> addStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _requireOwner();
    final normalized = email.trim().toLowerCase();
    if (_users.any((u) => u.email == normalized)) {
      throw const ValidationException('email', FieldError.duplicate);
    }
    final user = AppUser(
      id: const Uuid().v4(),
      name: name.trim(),
      email: normalized,
      role: role,
      shopId: DemoData.shopId,
      shopName: DemoData.owner.shopName,
    );
    _users.add(user);
    _passwords[normalized] = password;
    return user;
  }

  @override
  Future<void> removeStaff(String userId) async {
    _requireOwner();
    if (userId == currentUser()?.id) throw const PermissionDeniedException();
    _users.removeWhere((u) => u.id == userId);
  }

  void _requireOwner() {
    if (currentUser()?.isOwner != true) throw const PermissionDeniedException();
  }
}
