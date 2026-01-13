import 'package:get_it/get_it.dart';
import '../../services/tcp_client.dart';
import '../services/controller_registry.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<ControllerRegistry>(() => ControllerRegistry());
  getIt.registerLazySingleton<TCPClient>(() => TCPClient());
}
