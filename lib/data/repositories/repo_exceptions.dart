import '../../logic/domain/validators.dart';
import '../models/product.dart';

/// Second validation layer: repositories refuse bad data even if a form let it through.
class ValidationException implements Exception {
  final String field;
  final FieldError error;

  const ValidationException(this.field, this.error);

  @override
  String toString() => 'ValidationException($field: ${error.name})';
}

class DuplicateBarcodeException implements Exception {
  final String barcode;
  final String existingName;

  const DuplicateBarcodeException(this.barcode, this.existingName);

  @override
  String toString() => 'DuplicateBarcodeException($barcode belongs to $existingName)';
}

class NotFoundException implements Exception {
  final String what;
  const NotFoundException(this.what);

  @override
  String toString() => 'NotFoundException($what)';
}

/// A stock count is running, so ordinary movements are blocked.
class CountInProgressException implements Exception {
  const CountInProgressException();
}

class PermissionDeniedException implements Exception {
  const PermissionDeniedException();
}

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
}

void ensureValidProduct(Product product) {
  final checks = {
    'name': validateProductName(product.name),
    'barcode': validateBarcode(product.barcode),
    'reorderPoint': product.reorderPoint < 0 ? FieldError.negative : null,
    'unit': product.unit.trim().isEmpty ? FieldError.required : null,
  };
  for (final entry in checks.entries) {
    if (entry.value != null) throw ValidationException(entry.key, entry.value!);
  }
}
