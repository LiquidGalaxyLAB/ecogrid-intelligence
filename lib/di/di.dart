import 'package:get_it/get_it.dart';
import 'data_di.dart';
import 'domain_di.dart';
import 'presentation_di.dart';
import 'service_di.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  initServices();
  initData();
  initDomain();
  initPresentation();
}
