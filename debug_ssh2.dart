import 'package:dartssh2/dartssh2.dart';

void main() async {
  try {
    final client = SSHClient(
      await SSHSocket.connect('localhost', 2222),
      username: 'lg',
      onPasswordRequest: () => 'lg',
    );
    final res = await client.run('cat ~/earth/kml/master/myplaces.kml');
    print('--- master myplaces.kml ---');
    print(String.fromCharCodes(res));
    client.close();
  } catch(e) {
    print('Error: ' + e.toString());
  }
}
