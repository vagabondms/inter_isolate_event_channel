import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'inter_isolate_event_channel_platform_interface.dart';

/// An implementation of [InterIsolateEventChannelPlatform] that uses method channels.
class MethodChannelInterIsolateEventChannel extends InterIsolateEventChannelPlatform {
  /// The method channel used to emit events to the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('inter_isolate_event/emit');

  /// The event channel used to receive broadcast events from the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('inter_isolate_event/broadcast');

  /// Cached broadcast stream
  Stream<dynamic>? _broadcastStream;

  @override
  Future<void> emit(String eventType, dynamic payload) async {
    try {
      await methodChannel.invokeMethod('emitEvent', {
        'eventType': eventType,
        'payload': payload,
      });
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to emit event: ${e.message}',
        details: e.details,
      );
    }
  }

  @override
  Stream<dynamic> get broadcastStream {
    _broadcastStream ??= eventChannel.receiveBroadcastStream();
    return _broadcastStream!;
  }
}
