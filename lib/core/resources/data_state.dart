abstract class DataState<T> {
  const DataState();
}

class DataSuccess<T> extends DataState<T> {
  final T data;
  const DataSuccess(this.data);
}

class DataFailed<T> extends DataState<T> {
  final String message;
  const DataFailed(this.message);
}
