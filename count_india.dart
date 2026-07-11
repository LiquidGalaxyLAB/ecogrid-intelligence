import 'dart:io';
void main() async {
  final lines = await File('assets/data/global_powerplant_dataset_1 - Sheet1.csv').readAsLines();
  int indiaCount = 0;
  for (var line in lines) {
    if (line.contains('India') || line.contains('IND')) indiaCount++;
  }
  print('India plants: \$indiaCount');
}
