abstract class DataState<T> {
  final T? data;
  final Exception? exception;
  const DataState({this.data, this.exception});
}

class DataLoading<T> extends DataState<T> {
  const DataLoading() : super();
}

class DataEmpty<T> extends DataState<T> {
  const DataEmpty() : super();
}

class DataSuccess<T> extends DataState<T> {
  const DataSuccess(T data) : super(data: data);
}

class DataFailure<T> extends DataState<T> {
  const DataFailure(Exception exception) : super(exception: exception);
}
