import 'package:dartssh2/dartssh2.dart';

void main() async {
  try {
    final client = SSHClient(
      await SSHSocket.connect('192.168.29.146', 2222),
      username: 'lg',
      onPasswordRequest: () => 'lg',
    );
    final res = await client.run('curl -s http://localhost:81/sync_nlc.php');
    print('--- sync_nlc.php output ---');
    print(String.fromCharCodes(res));
    client.close();
  } catch(e) {
    print('Error: ' + e.toString());
  }
}
