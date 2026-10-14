import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';

abstract interface class NetworkInfoRepository {
  Future<NetworkSnapshot> getCurrentNetwork();
}

class NetworkInfoException implements Exception {
  const NetworkInfoException(this.code, this.userMessage);

  final String code;
  final String userMessage;

  @override
  String toString() => 'NetworkInfoException($code)';
}
