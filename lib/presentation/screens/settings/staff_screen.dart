import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../di/service_locator.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/staff/staff_cubit.dart';
import '../../../logic/domain/validators.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/ui.dart';

/// Two or three accounts for one shop. Only the owner can change them.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StaffCubit(getIt<AuthRepo>())..load(),
      child: const _StaffView(),
    );
  }
}

class _StaffView extends StatelessWidget {
  const _StaffView();

  Future<void> add(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(value: context.read<StaffCubit>(), child: const _AddStaffSheet()),
    );
    if (added == true && context.mounted) MySnackBar.success(context, context.l10n.staffAdded);
  }

  Future<void> remove(BuildContext context, AppUser user) async {
    final l10n = context.l10n;
    final cubit = context.read<StaffCubit>();
    final result = await showDialog(
      context: context,
      builder: (_) => MyConfirmationDialog(
        dialogType: 'danger',
        title: l10n.removeStaffTitle,
        message: l10n.removeStaffBody(user.name),
        confirmLabel: l10n.remove,
        onConfirm: () async => toReturnResult(l10n, await cubit.remove(user.id)),
      ),
    );
    if (result != null && context.mounted) MySnackBar.success(context, l10n.staffRemoved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final me = context.read<AuthCubit>().user;
    final isOwner = me?.isOwner ?? false;

    return Scaffold(
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => add(context),
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              icon: AppIcon(AppIcons.plus, color: c.onPrimary),
              label: Text(l10n.addStaff),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopBar(leadingIcon: AppIcons.back, title: TopBar.titleText(l10n.staffAccounts)),
            if (!isOwner)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(l10n.ownerOnlyStaff, style: TextStyle(fontSize: 14, color: c.textSecondary)),
              ),
            Expanded(
              child: BlocBuilder<StaffCubit, StaffState>(
                builder: (context, state) => switch (state) {
                  StaffLoading() => const Center(child: CircularProgressIndicator()),
                  StaffError(:final failure) => Center(
                      child: MessageView(
                        icon: AppIcons.warning,
                        title: l10n.failure(failure),
                        actionLabel: l10n.retry,
                        onAction: context.read<StaffCubit>().load,
                      ),
                    ),
                  StaffLoaded(:final users) => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final user = users[index];
                        final isMe = user.id == me?.id;
                        return CardBox(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: user.isOwner ? c.primaryContainer : c.surfaceMuted,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  user.initial,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: user.isOwner ? c.primaryDark : c.textStrong,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? '${user.name} (${l10n.you})' : user.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${user.email} · ${l10n.roleName(user.role)}',
                                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwner && !isMe)
                                CircleIconButton(
                                  icon: AppIcons.trash,
                                  iconSize: 20,
                                  color: c.error,
                                  tooltip: l10n.remove,
                                  onTap: () => remove(context, user),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStaffSheet extends StatefulWidget {
  const _AddStaffSheet();

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  UserRole role = UserRole.staff;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<ReturnResult> submit() async {
    final l10n = context.l10n;
    if (!formKey.currentState!.validate()) return ReturnResult(state: false, message: l10n.errorValidation);
    final navigator = Navigator.of(context);
    final result = await context.read<StaffCubit>().add(
          name: name.text,
          email: email.text,
          password: password.text,
          role: role,
        );
    if (result.ok) navigator.pop(true);
    return toReturnResult(l10n, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.addStaff, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextFormField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.staffName),
              validator: (value) => l10n.field(validateProductName(value)),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.email),
              validator: (value) => l10n.field(validateEmail(value)),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password),
              validator: (value) => l10n.field(validatePassword(value)),
            ),
            const SizedBox(height: 18),
            SegmentedTabs<UserRole>(
              values: const [UserRole.staff, UserRole.owner],
              selected: role,
              height: 50,
              onChanged: (value) => setState(() => role = value),
              labelBuilder: (value, _) => Text(l10n.roleName(value)),
            ),
            const SizedBox(height: 20),
            MyProgressButton(label: l10n.addStaff, onPressed: submit),
          ],
        ),
      ),
    );
  }
}
