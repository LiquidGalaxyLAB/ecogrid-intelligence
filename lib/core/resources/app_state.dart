abstract class AppState<T> {
  const AppState();
}

class AppStateLoading<T> extends AppState<T> {}

class AppStateSuccess<T> extends AppState<T> {
  final T data;
  const AppStateSuccess(this.data);
}

class AppStateError<T> extends AppState<T> {
  final String message;
  const AppStateError(this.message);
}
