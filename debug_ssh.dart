import 'package:dartssh2/dartssh2.dart';

void main() async {
  try {
    final client = SSHClient(
      await SSHSocket.connect('localhost', 2222),
      username: 'lg',
      onPasswordRequest: () => 'lg',
    );
    final res1 = await client.run('cat /var/www/html/kmls.txt');
    print('--- kmls.txt ---');
    print(String.fromCharCodes(res1));

    final res2 = await client.run('ls -lh /var/www/html/kml/kmls.kml');
    print('--- kmls.kml stat ---');
    print(String.fromCharCodes(res2));

    final res3 = await client.run('cat ~/earth/kml/master/myplaces.kml');
    print('--- master myplaces.kml ---');
    print(String.fromCharCodes(res3));

    client.close();
  } catch(e) {
    print('Error: \');
  }
}
