import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rx_event_channel_method_channel.dart';

abstract class RxEventChannelPlatform extends PlatformInterface {
  /// Constructs a RxEventChannelPlatform.
  RxEventChannelPlatform() : super(token: _token);

  static final Object _token = Object();

  static RxEventChannelPlatform _instance = MethodChannelRxEventChannel();

  /// The default instance of [RxEventChannelPlatform] to use.
  ///
  /// Defaults to [MethodChannelRxEventChannel].
  static RxEventChannelPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RxEventChannelPlatform] when
  /// they register themselves.
  static set instance(RxEventChannelPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
