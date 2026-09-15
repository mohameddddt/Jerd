import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../data/models/app_user.dart';
import '../data/models/movement.dart';
import '../l10n/gen/app_localizations.dart';
import '../logic/cubits/failure.dart';
import '../logic/domain/validators.dart';
import 'widgets/progress_button.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String get localeName => Localizations.localeOf(this).toLanguageTag();
}

extension FailureText on AppLocalizations {
  String failure(Failure failure) => switch (failure.kind) {
        FailureKind.network => errorNetwork,
        FailureKind.invalidCredentials => errorInvalidCredentials,
        FailureKind.duplicateBarcode => errorDuplicateBarcode(failure.detail ?? ''),
        FailureKind.validation => errorValidation,
        FailureKind.notFound => errorNotFound,
        FailureKind.countInProgress => errorCountInProgress,
        FailureKind.permissionDenied => errorPermissionDenied,
        FailureKind.serverNotConfigured => errorServerNotConfigured,
        FailureKind.server => errorServer(failure.detail ?? ''),
        FailureKind.unknown => errorUnknown,
      };

  String? field(FieldError? error) => switch (error) {
        null => null,
        FieldError.required => fieldRequired,
        FieldError.invalidEmail => fieldInvalidEmail,
        FieldError.passwordTooShort => fieldPasswordTooShort(minPasswordLength),
        FieldError.invalidNumber => fieldInvalidNumber,
        FieldError.negative => fieldNegative,
        FieldError.invalidBarcode => fieldInvalidBarcode,
        FieldError.zeroQuantity => fieldZeroQuantity,
        FieldError.tooLong => fieldTooLong,
        FieldError.duplicate => fieldDuplicate,
      };

  String roleName(UserRole role) => role == UserRole.owner ? roleOwner : roleStaff;

  /// "Received 12", "Sold 1", "Adjusted −2", "Stock count +3".
  String movementTitle(MovementReason reason, int delta) => switch (reason) {
        MovementReason.received => historyReceived(delta.abs()),
        MovementReason.sold => historySold(delta.abs()),
        MovementReason.adjusted => historyAdjusted(signed(delta)),
        MovementReason.counted => historyCounted(signed(delta)),
      };
}

/// Adapts a cubit's result for [MyProgressButton], which shows the snackbar.
ReturnResult toReturnResult(AppLocalizations l10n, ActionResult result, {String success = ''}) =>
    result.ok
        ? ReturnResult(state: true, message: success)
        : ReturnResult(state: false, message: l10n.failure(result.failure!));

/// Signed amount with a true minus sign.
String signed(int value) => value > 0 ? '+$value' : value < 0 ? '−${value.abs()}' : '0';

/// "Today 10:05", "Yesterday 17:20", "Mon 09:12" or "12 Sep 09:12" — localised.
String formatWhen(BuildContext context, DateTime date, {DateTime? now}) {
  final l10n = context.l10n;
  final locale = context.localeName;
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;
  final time = DateFormat.Hm(locale).format(date);
  final label = switch (days) {
    0 => l10n.today,
    1 => l10n.yesterday,
    > 1 && < 7 => DateFormat.E(locale).format(date),
    _ => DateFormat.MMMd(locale).format(date),
  };
  return '$label $time';
}

String formatTime(BuildContext context, DateTime date) =>
    DateFormat.Hm(context.localeName).format(date);
