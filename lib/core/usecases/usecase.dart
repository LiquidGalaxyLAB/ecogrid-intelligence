abstract class UseCase<R, P> {
  Stream<R> call({P? params});
}

abstract class SyncUseCase<R, P> {
  R call(P params);
}

abstract class SyncUseCaseNoParams<R> {
  R call();
}
