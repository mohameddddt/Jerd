import '../../data/repositories/repo_exceptions.dart';
import '../../data/services/sync_service.dart';
import '../../infrastructure/api_client.dart';

/// What went wrong, without wording — the UI localises it.
enum FailureKind {
  network,
  invalidCredentials,
  duplicateBarcode,
  validation,
  notFound,
  countInProgress,
  permissionDenied,
  serverNotConfigured,
  server,
  unknown,
}

class Failure {
  final FailureKind kind;

  /// Extra detail, e.g. the product that already owns a barcode.
  final String? detail;

  const Failure(this.kind, [this.detail]);

  factory Failure.from(Object error) => switch (error) {
        NetworkException() => const Failure(FailureKind.network),
        InvalidCredentialsException() => const Failure(FailureKind.invalidCredentials),
        DuplicateBarcodeException(:final existingName) =>
          Failure(FailureKind.duplicateBarcode, existingName),
        ValidationException(:final field) => Failure(FailureKind.validation, field),
        NotFoundException() => const Failure(FailureKind.notFound),
        CountInProgressException() => const Failure(FailureKind.countInProgress),
        PermissionDeniedException() => const Failure(FailureKind.permissionDenied),
        SyncNotConfiguredException() => const Failure(FailureKind.serverNotConfigured),
        ApiException(:final isUnauthorized) when isUnauthorized =>
          const Failure(FailureKind.invalidCredentials),
        ApiException(:final message) => Failure(FailureKind.server, message),
        _ => Failure(FailureKind.unknown, error.toString()),
      };

  @override
  bool operator ==(Object other) =>
      other is Failure && other.kind == kind && other.detail == detail;

  @override
  int get hashCode => Object.hash(kind, detail);

  @override
  String toString() => 'Failure(${kind.name}${detail == null ? '' : ': $detail'})';
}

/// Result of a user action run by a cubit; side effects stay in the UI.
class ActionResult {
  final Failure? failure;

  const ActionResult.ok() : failure = null;
  const ActionResult.failed(Failure this.failure);

  bool get ok => failure == null;
}
