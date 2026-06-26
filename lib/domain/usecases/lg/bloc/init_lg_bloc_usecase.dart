import '../../../../service/ssh_service.dart';

class InitLgBlocUseCase {
  final SSHService sshService;

  InitLgBlocUseCase(this.sshService);

  Stream<bool> call() {
    return sshService.connectionStream;
  }
}
