import 'package:flutter/services.dart';
import 'package:spy_dev_det/features/network/domain/network_info_repository.dart';
import 'package:spy_dev_det/features/network/domain/network_snapshot.dart';

class NativeNetworkInfoRepository implements NetworkInfoRepository {
  const NativeNetworkInfoRepository();

  static const _channel = MethodChannel('yusufs.turan.spydevdet/network_info');

  @override
  Future<NetworkSnapshot> getCurrentNetwork() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getNetworkSnapshot',
      );
      if (result == null) {
        throw const NetworkInfoException(
          'EMPTY_RESPONSE',
          'İşletim sistemi ağ bilgisi döndürmedi.',
        );
      }

      return NetworkSnapshot(
        localIpv4: _requiredString(result, 'localIpv4'),
        prefixLength: _requiredInt(result, 'prefixLength'),
        interfaceName: _requiredString(result, 'interfaceName'),
        isWifi: _requiredBool(result, 'isWifi'),
        isEthernet: _optionalBool(result, 'isEthernet'),
        isVpn: _requiredBool(result, 'isVpn'),
        gatewayIpv4: result['gatewayIpv4'] as String?,
      );
    } on PlatformException catch (error) {
      throw NetworkInfoException(
        error.code,
        error.message ?? 'Ağ bilgisi okunamadı.',
      );
    } on MissingPluginException {
      throw const NetworkInfoException(
        'PLATFORM_UNAVAILABLE',
        'Ağ bilgisi bu platformda desteklenmiyor.',
      );
    } on NetworkInfoException {
      rethrow;
    } on Object {
      throw const NetworkInfoException(
        'INVALID_RESPONSE',
        'İşletim sistemi geçersiz bir ağ bilgisi döndürdü.',
      );
    }
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw NetworkInfoException(
      'INVALID_RESPONSE',
      'Ağ bilgisinde $key alanı eksik.',
    );
  }

  static int _requiredInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    throw NetworkInfoException(
      'INVALID_RESPONSE',
      'Ağ bilgisinde $key alanı eksik.',
    );
  }

  static bool _requiredBool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is bool) {
      return value;
    }
    throw NetworkInfoException(
      'INVALID_RESPONSE',
      'Ağ bilgisinde $key alanı eksik.',
    );
  }

  static bool _optionalBool(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is bool ? value : false;
  }
}
