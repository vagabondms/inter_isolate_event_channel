import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rx_event_channel_platform_interface.dart';

/// An implementation of [RxEventChannelPlatform] that uses method channels.
class MethodChannelRxEventChannel extends RxEventChannelPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rx_event_channel');
}
