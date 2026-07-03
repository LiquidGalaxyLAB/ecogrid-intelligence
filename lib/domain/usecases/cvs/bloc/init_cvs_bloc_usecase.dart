import '../../../repository/cvs_repository.dart';

class InitCvsBlocUseCase {
  final CvsRepository _repository;
  InitCvsBlocUseCase(this._repository);
  void call() {
    _repository.clearCache();
  }
}
