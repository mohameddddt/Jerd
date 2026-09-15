import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../infrastructure/app_logger.dart';
import '../../../infrastructure/app_prefs.dart';
import '../failure.dart';
import 'auth_state.dart';

typedef SessionHook = Future<void> Function(AppUser user);

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo repo;
  final AppPrefs prefs;
  final SessionHook? afterLogin;
  final SessionHook? beforeLogout;

  AuthCubit({
    required this.repo,
    required this.prefs,
    this.afterLogin,
    this.beforeLogout,
  }) : super(const AuthInitial());

  AppUser? get user => switch (state) {
        Authenticated(:final user) => user,
        _ => null,
      };

  /// Stays logged in across launches — the session works offline.
  Future<void> restoreSession() async {
    final saved = prefs.user;
    if (prefs.isLoggedIn && saved != null && prefs.token != null) {
      emit(Authenticated(saved));
      _runHook(afterLogin, saved);
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final session = await repo.login(email, password);
      await prefs.saveSession(session.user, session.token);
      await afterLogin?.call(session.user);
      emit(Authenticated(session.user));
    } catch (e, st) {
      if (Failure.from(e).kind == FailureKind.unknown) AppLogger.error('Login failed', e, st);
      emit(AuthError(Failure.from(e)));
    }
  }

  Future<void> logout() async {
    final current = user;
    if (current != null) await _runHook(beforeLogout, current);
    await repo.logout();
    await prefs.clearSession();
    emit(const Unauthenticated());
  }

  Future<void> _runHook(SessionHook? hook, AppUser user) async {
    try {
      await hook?.call(user);
    } catch (e, st) {
      AppLogger.error('Session hook failed', e, st);
    }
  }
}
