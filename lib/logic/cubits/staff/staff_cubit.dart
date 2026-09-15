import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repo.dart';
import '../failure.dart';

sealed class StaffState extends Equatable {
  const StaffState();

  @override
  List<Object?> get props => [];
}

class StaffLoading extends StaffState {
  const StaffLoading();
}

class StaffLoaded extends StaffState {
  final List<AppUser> users;

  const StaffLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class StaffError extends StaffState {
  final Failure failure;

  const StaffError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Owner manages the two or three accounts of one shop.
class StaffCubit extends Cubit<StaffState> {
  final AuthRepo repo;

  StaffCubit(this.repo) : super(const StaffLoading());

  Future<void> load() async {
    try {
      final users = await repo.getStaff();
      if (!isClosed) emit(StaffLoaded(users));
    } catch (e) {
      if (!isClosed) emit(StaffError(Failure.from(e)));
    }
  }

  Future<ActionResult> add({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      await repo.addStaff(name: name, email: email, password: password, role: role);
      await load();
      return const ActionResult.ok();
    } catch (e) {
      return ActionResult.failed(Failure.from(e));
    }
  }

  Future<ActionResult> remove(String userId) async {
    try {
      await repo.removeStaff(userId);
      await load();
      return const ActionResult.ok();
    } catch (e) {
      return ActionResult.failed(Failure.from(e));
    }
  }
}
