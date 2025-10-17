import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'inter_isolate_event_channel_method_channel.dart';

abstract class InterIsolateEventChannelPlatform extends PlatformInterface {
  /// Constructs a InterIsolateEventChannelPlatform.
  InterIsolateEventChannelPlatform() : super(token: _token);

  static final Object _token = Object();

  static InterIsolateEventChannelPlatform _instance = MethodChannelInterIsolateEventChannel();

  /// The default instance of [InterIsolateEventChannelPlatform] to use.
  ///
  /// Defaults to [MethodChannelInterIsolateEventChannel].
  static InterIsolateEventChannelPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [InterIsolateEventChannelPlatform] when
  /// they register themselves.
  static set instance(InterIsolateEventChannelPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Broadcasts an event to all isolates/engines.
  ///
  /// [eventType] - Event type identifier (e.g., 'call.invite')
  /// [payload] - Data to send with the event
  Future<void> emit(String eventType, dynamic payload);

  /// Returns the broadcast event stream.
  Stream<dynamic> get broadcastStream;
}
