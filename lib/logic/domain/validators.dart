/// Validation lives here, free of Flutter, so the form and the repository
/// share the same rules. The UI maps each error to a localised message.
enum FieldError {
  required,
  invalidEmail,
  passwordTooShort,
  invalidNumber,
  negative,
  invalidBarcode,
  zeroQuantity,
  tooLong,
  duplicate,
}

const minPasswordLength = 6;
const maxNameLength = 80;

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _digits = RegExp(r'^\d+$');

FieldError? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return FieldError.required;
  if (!_email.hasMatch(text)) return FieldError.invalidEmail;
  return null;
}

FieldError? validatePassword(String? value) {
  if (value == null || value.isEmpty) return FieldError.required;
  if (value.length < minPasswordLength) return FieldError.passwordTooShort;
  return null;
}

FieldError? validateProductName(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return FieldError.required;
  if (text.length > maxNameLength) return FieldError.tooLong;
  return null;
}

/// EAN-8, UPC-A, EAN-13 and ITF-14 are all 8–14 digits; shops also print
/// short internal codes, so anything from 4 digits is accepted.
FieldError? validateBarcode(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return FieldError.required;
  if (!_digits.hasMatch(text) || text.length < 4 || text.length > 14) {
    return FieldError.invalidBarcode;
  }
  return null;
}

FieldError? validateReorderPoint(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return FieldError.required;
  final number = int.tryParse(text);
  if (number == null) return FieldError.invalidNumber;
  if (number < 0) return FieldError.negative;
  return null;
}

/// [allowNegative] is true for adjustments, which may remove stock.
FieldError? validateQuantity(int? value, {required bool allowNegative}) {
  if (value == null) return FieldError.invalidNumber;
  if (value == 0) return FieldError.zeroQuantity;
  if (!allowNegative && value < 0) return FieldError.negative;
  return null;
}
