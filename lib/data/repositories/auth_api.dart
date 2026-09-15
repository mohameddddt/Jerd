import '../../infrastructure/api_client.dart';
import '../../logic/domain/validators.dart';
import '../models/app_user.dart';
import 'auth_repo.dart';
import 'repo_exceptions.dart';

class AuthApi implements AuthRepo {
  final ApiClient api;

  AuthApi(this.api);

  @override
  Future<Session> login(String email, String password) async {
    try {
      final json = await api.post('/auth/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      return Session(
        AppUser.fromJson(json['user'] as Map<String, dynamic>),
        json['token'] as String,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 400) throw const InvalidCredentialsException();
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await api.post('/auth/logout', const {});
    } on Exception {
      // Signing out must work offline; the token simply expires server-side.
    }
  }

  @override
  Future<List<AppUser>> getStaff() async {
    final json = await api.get('/staff');
    return (json['users'] as List? ?? const [])
        .map((row) => AppUser.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AppUser> addStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final json = await api.post('/staff', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role.name,
      });
      return AppUser.fromJson(json['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 403) throw const PermissionDeniedException();
      if (e.statusCode == 409) throw const ValidationException('email', FieldError.duplicate);
      rethrow;
    }
  }

  @override
  Future<void> removeStaff(String userId) async {
    try {
      await api.delete('/staff/$userId');
    } on ApiException catch (e) {
      if (e.statusCode == 403) throw const PermissionDeniedException();
      rethrow;
    }
  }
}
