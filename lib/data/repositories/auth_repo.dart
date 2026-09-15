import '../models/app_user.dart';

class Session {
  final AppUser user;
  final String token;

  const Session(this.user, this.token);
}

abstract class AuthRepo {
  /// Throws [InvalidCredentialsException] or a network error.
  Future<Session> login(String email, String password);

  Future<void> logout();

  Future<List<AppUser>> getStaff();

  /// Owner only.
  Future<AppUser> addStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  /// Owner only.
  Future<void> removeStaff(String userId);
}
