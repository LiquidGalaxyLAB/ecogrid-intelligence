/// Base class for asynchronous use cases.
abstract class UseCase<R, P> {
  Future<R> call({P? params});
}

/// Base class for synchronous use cases (no IO, pure domain logic).
abstract class SyncUseCase<R, P> {
  R call(P params);
}

/// Base class for synchronous use cases with no parameters.
abstract class SyncUseCaseNoParams<R> {
  R call();
}
