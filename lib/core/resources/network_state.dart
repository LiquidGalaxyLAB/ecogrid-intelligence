abstract class NetworkState<T> {
  const NetworkState();
}

class NetworkIdle<T> extends NetworkState<T> {
  const NetworkIdle();
}

class NetworkLoading<T> extends NetworkState<T> {
  const NetworkLoading();
}

class NetworkSuccess<T> extends NetworkState<T> {
  final T data;
  const NetworkSuccess(this.data);
}

class NetworkFailure<T> extends NetworkState<T> {
  final Exception? exception;
  final int? statusCode;
  const NetworkFailure({this.exception, this.statusCode});
}
