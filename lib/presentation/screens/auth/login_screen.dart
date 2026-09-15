import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/demo_data.dart';
import '../../../infrastructure/app_config.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/auth/auth_state.dart';
import '../../../logic/domain/validators.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../themes/app_themes.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/progress_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController(text: AppConfig.hasBackend ? '' : DemoData.owner.email);
  final password = TextEditingController(text: AppConfig.hasBackend ? '' : DemoData.password);
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<ReturnResult> login() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) {
      return ReturnResult(state: false, message: context.l10n.errorValidation);
    }
    final auth = context.read<AuthCubit>();
    final l10n = context.l10n;
    await auth.login(email.text, password.text);
    // The gate swaps to the home screen on success; only errors need a message.
    return switch (auth.state) {
      AuthError(:final failure) => ReturnResult(state: false, message: l10n.failure(failure)),
      _ => const ReturnResult(state: true, message: ''),
    };
  }

  Widget fieldIcon(String icon) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
        child: AppIcon(icon, size: 22, color: context.palette.hint),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: AutofillGroup(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(child: _Brand()),
                        const SizedBox(height: 24),
                        Text(l10n.signIn, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: fieldIcon(AppIcons.mail),
                            prefixIconConstraints: const BoxConstraints(),
                          ),
                          validator: (value) => l10n.field(validateEmail(value)),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: password,
                          obscureText: obscure,
                          obscuringCharacter: '•',
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => login(),
                          style: TextStyle(fontSize: obscure ? 18 : 16, letterSpacing: obscure ? 3 : 0),
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: fieldIcon(AppIcons.lock),
                            prefixIconConstraints: const BoxConstraints(),
                            suffixIcon: IconButton(
                              tooltip: obscure ? l10n.showPassword : l10n.hidePassword,
                              onPressed: () => setState(() => obscure = !obscure),
                              icon: AppIcon(
                                obscure ? AppIcons.eye : AppIcons.eyeOff,
                                size: 22,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          validator: (value) => l10n.field(validatePassword(value)),
                        ),
                        const SizedBox(height: 24),
                        MyProgressButton(label: l10n.signIn, height: 60, onPressed: login),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () => MySnackBar.success(context, l10n.forgotPasswordHelp),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.all(10),
                              textStyle: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.noAccount,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: c.textSecondary),
                        ),
                        if (!AppConfig.hasBackend) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.demoAccounts(DemoData.staff.email, DemoData.password),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: c.hint),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [BoxShadow(color: Color(0x408C3C19), blurRadius: 24, offset: Offset(0, 10))],
            ),
            child: Text(
              'جرد',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: c.onPrimary),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Jerd', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          Text(
            context.l10n.loginTagline,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, height: 1.4, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
