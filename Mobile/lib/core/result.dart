import 'error/failures.dart';

/// Minimal Either-like type: a call either succeeds with [T] or fails with a [Failure].
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>() => success(self.value),
      Err<T>() => failure(self.failure),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
