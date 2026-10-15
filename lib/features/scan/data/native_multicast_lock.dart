import 'dart:io';

import 'package:flutter/services.dart';

class NativeMulticastLock {
  const NativeMulticastLock();

  static const _channel = MethodChannel('yusufs.turan.spydevdet/network_info');

  Future<void> acquire() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('acquireMulticastLock');
    }
  }

  Future<void> release() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('releaseMulticastLock');
    }
  }
}
