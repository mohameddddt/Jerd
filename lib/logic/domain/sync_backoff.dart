const baseBackoff = Duration(seconds: 30);
const maxBackoff = Duration(hours: 1);

/// Exponential backoff: 0 attempts → no wait, then 30s, 1m, 2m, 4m … capped at 1h.
Duration backoffFor(
  int attempts, {
  Duration base = baseBackoff,
  Duration max = maxBackoff,
}) {
  if (attempts <= 0) return Duration.zero;
  // Cap the exponent so the shift never overflows.
  final exponent = (attempts - 1).clamp(0, 30);
  final millis = base.inMilliseconds * (1 << exponent);
  return millis >= max.inMilliseconds ? max : Duration(milliseconds: millis);
}

/// Whether a job that already failed [attempts] times may be retried at [now].
bool isRetryDue({
  required int attempts,
  required DateTime? lastAttemptAt,
  required DateTime now,
  Duration base = baseBackoff,
  Duration max = maxBackoff,
}) {
  if (attempts <= 0 || lastAttemptAt == null) return true;
  return !now.isBefore(lastAttemptAt.add(backoffFor(attempts, base: base, max: max)));
}
