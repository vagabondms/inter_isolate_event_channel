import 'inter_isolate_event_channel_platform_interface.dart';

/// Inter-Isolate Event Channel for broadcasting events across multiple isolates/engines
class InterIsolateEventChannel {
  static InterIsolateEventChannelPlatform get _platform =>
      InterIsolateEventChannelPlatform.instance;

  /// Validates whether a value is JSON-serializable.
  ///
  /// Supported types: null, bool, num (int, double), String, List, Map
  /// List and Map are validated recursively.
  static bool _isJsonSerializable(dynamic value) {
    if (value == null) return true;
    if (value is bool || value is num || value is String) return true;

    if (value is List) {
      return value.every(_isJsonSerializable);
    }

    if (value is Map) {
      return value.keys.every((key) => key is String) &&
             value.values.every(_isJsonSerializable);
    }

    return false;
  }

  /// Broadcasts an event to all isolates/engines.
  ///
  /// [eventType] - Event type identifier (e.g., 'call.invite')
  /// [payload] - Data to send with the event (must be JSON-serializable)
  ///
  /// Throws [ArgumentError] if [eventType] is empty.
  /// Throws [ArgumentError] if [payload] is not JSON-serializable.
  /// Throws [PlatformException] if the native platform fails to emit the event.
  static Future<void> emit(String eventType, dynamic payload) async {
    if (eventType.isEmpty) {
      throw ArgumentError('eventType cannot be empty');
    }

    if (!_isJsonSerializable(payload)) {
      throw ArgumentError(
        'payload must be JSON-serializable (null, bool, num, String, List, Map). '
        'Got: ${payload.runtimeType}'
      );
    }

    await _platform.emit(eventType, payload);
  }

  /// Returns a stream for a specific event type.
  ///
  /// [eventType] - Event type to subscribe to (e.g., 'call.invite')
  /// [T] - Expected payload type (recommended for type safety)
  ///
  /// Returns a stream that emits only the payload of events matching [eventType].
  ///
  /// Events with mismatched payload types are automatically skipped.
  /// In debug mode, a warning is printed via assert when type mismatches occur.
  ///
  /// Example:
  /// ```dart
  /// // Specify Generic type for type safety
  /// InterIsolateEventChannel.on<Map<String, dynamic>>('user.login').listen((payload) {
  ///   String userId = payload['userId']; // Type safe!
  /// });
  ///
  /// // Without Generic, payload is dynamic
  /// InterIsolateEventChannel.on('user.login').listen((payload) {
  ///   // payload is dynamic
  /// });
  /// ```
  ///
  /// Throws [ArgumentError] if [eventType] is empty.
  static Stream<T> on<T>(String eventType) {
    if (eventType.isEmpty) {
      throw ArgumentError('eventType cannot be empty');
    }

    return _platform.broadcastStream.where((event) {
      if (event is! Map || event['eventType'] != eventType) {
        return false;
      }

      final payload = event['payload'];

      // Type validation (permissive mode: skip if type doesn't match)
      if (payload is! T) {
        assert(() {
          // ignore: avoid_print
          print(
            'Warning: Event "$eventType" payload type mismatch. '
            'Expected: $T, Actual: ${payload.runtimeType}'
          );
          return true;
        }());
        return false;
      }

      return true;
    }).map((event) => event['payload'] as T);
  }
}
