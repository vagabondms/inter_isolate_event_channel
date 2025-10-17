# inter_isolate_event_channel

[![pub package](https://img.shields.io/pub/v/inter_isolate_event_channel.svg)](https://pub.dev/packages/inter_isolate_event_channel)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for broadcasting events across multiple isolates/engines through the native layer.

## Features

- ✅ **Event Broadcasting**: Broadcast events from one isolate/engine to all other isolates/engines
- ✅ **Event Type Filtering**: Subscribe to specific event types
- ✅ **Type Safety**: Generic type parameters with compile-time type checking
- ✅ **JSON Validation**: Automatic payload validation at emit time
- ✅ **Efficient Routing**: Event routing through native layer (Android/iOS)
- ✅ **Memory Safety**: Proper resource management to prevent memory leaks
- ✅ **Platform Interface Pattern**: Well-structured plugin architecture
- ✅ **Comprehensive Error Handling**: Clear error messages and exceptions

## Use Cases

This plugin is useful in the following scenarios:

- **Multi-Engine Flutter Apps**: Multiple Flutter engines within a native app
- **Add-to-App Scenarios**: Integrating Flutter into existing native apps
- **Background Isolate Communication**: Sharing events between background and UI isolates
- **Real-time Notifications**: Instantly propagating events from one screen to all others

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  inter_isolate_event_channel: ^1.0.1
```

Then install packages:

```bash
flutter pub get
```

## Usage

### Basic Usage

#### Emitting Events

```dart
import 'package:inter_isolate_event_channel/inter_isolate_event_channel.dart';

// Emit an event
await InterIsolateEventChannel.emit(
  'call.invite',
  {'callerId': 'user123', 'callerName': 'Alice'}
);
```

#### Subscribing to Events

```dart
import 'package:inter_isolate_event_channel/inter_isolate_event_channel.dart';

// Subscribe to a specific event type with Generic for type safety
final subscription = InterIsolateEventChannel.on<Map<String, dynamic>>('call.invite').listen((payload) {
  // payload is automatically typed as Map<String, dynamic>
  print('Call invite received: ${payload['callerName']}');
  final callerId = payload['callerId']; // Type safe!
});

// Cancel subscription to prevent memory leaks
await subscription.cancel();
```

### Type Safety

#### Generic Type Specification

Specify generic types for compile-time type checking:

```dart
// Map type
InterIsolateEventChannel.on<Map<String, dynamic>>('user.login').listen((payload) {
  String userId = payload['userId']; // Type safe!
  String name = payload['name'];
});

// String type
InterIsolateEventChannel.on<String>('message.text').listen((message) {
  print(message.toUpperCase()); // String methods available
});

// int type
InterIsolateEventChannel.on<int>('counter.update').listen((count) {
  print(count * 2); // int operations available
});

// List type
InterIsolateEventChannel.on<List<dynamic>>('tags.updated').listen((tags) {
  print(tags.length); // List methods available
});
```

#### Type Mismatch Handling

Events with mismatched payload types are automatically skipped:

```dart
// String-only listener
InterIsolateEventChannel.on<String>('mixed.event').listen((message) {
  print('Text message: $message');
});

// int-only listener
InterIsolateEventChannel.on<int>('mixed.event').listen((number) {
  print('Number: $number');
});

// Send various types
await InterIsolateEventChannel.emit('mixed.event', 'Hello'); // String listener receives
await InterIsolateEventChannel.emit('mixed.event', 42);       // int listener receives
await InterIsolateEventChannel.emit('mixed.event', {'key': 'value'}); // Both skip
```

In debug mode, a warning is printed when type mismatches occur.

### Advanced Examples

#### Real-time Chat Message Broadcasting

```dart
// Engine 1: Send message
await InterIsolateEventChannel.emit('chat.message', {
  'roomId': 'room123',
  'message': 'Hello!',
  'sender': 'user456',
  'timestamp': DateTime.now().toIso8601String(),
});

// Engine 2, 3, 4...: Receive message (type safe)
InterIsolateEventChannel.on<Map<String, dynamic>>('chat.message').listen((payload) {
  if (payload['roomId'] == currentRoomId) {
    displayMessage(payload['message'], payload['sender']);
  }
});
```

#### State Synchronization

```dart
// Broadcast login state change
await InterIsolateEventChannel.emit('auth.login', {
  'userId': 'user789',
  'token': 'jwt_token_here',
});

// Update login state on all screens
InterIsolateEventChannel.on('auth.login').listen((payload) {
  updateAuthState(payload['userId'], payload['token']);
});

// Logout
await InterIsolateEventChannel.emit('auth.logout', null);
```

## How It Works

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│  Isolate A  │────────▶│  Native Layer    │────────▶│  Isolate B  │
│             │  emit() │  (Broadcaster)   │ stream  │             │
└─────────────┘         └──────────────────┘         └─────────────┘
                               │
                               ├────────────────────▶ Isolate C
                               ├────────────────────▶ Isolate D
                               └────────────────────▶ Isolate E
```

1. **Event Emission**: The `emit()` method sends events to the native layer via `MethodChannel`
2. **Native Broadcasting**: The singleton broadcaster forwards events to all registered EventSinks
3. **Event Reception**: Each isolate subscribes to the broadcast stream via `EventChannel`
4. **Filtering**: The Dart layer filters events by type using the `on()` method

## API Reference

### `InterIsolateEventChannel.emit(String eventType, dynamic payload)`

Broadcasts an event to all isolates/engines.

**Parameters:**
- `eventType` (String): Event type identifier (e.g., 'call.invite', 'message.new')
- `payload` (dynamic): Data to send (must be JSON-serializable)
  - Supported types: `null`, `bool`, `num` (int, double), `String`, `List`, `Map`
  - `List` and `Map` are validated recursively
  - `Map` keys must be `String`

**Returns:** `Future<void>`

**Throws:**
- `ArgumentError`: If eventType is empty or payload is not JSON-serializable
- `PlatformException`: If the native platform encounters an error

**Examples:**
```dart
// Valid payloads
await InterIsolateEventChannel.emit('event', null);
await InterIsolateEventChannel.emit('event', 'text');
await InterIsolateEventChannel.emit('event', 42);
await InterIsolateEventChannel.emit('event', [1, 2, 3]);
await InterIsolateEventChannel.emit('event', {'key': 'value'});
await InterIsolateEventChannel.emit('event', {
  'nested': {'data': [1, 2, 3]},
  'list': ['a', 'b', 'c'],
});

// Invalid payloads (throws ArgumentError)
await InterIsolateEventChannel.emit('event', DateTime.now()); // ❌
await InterIsolateEventChannel.emit('event', MyCustomClass()); // ❌
await InterIsolateEventChannel.emit('event', {1: 'value'}); // ❌ Non-String key
```

### `InterIsolateEventChannel.on<T>(String eventType)`

Returns a stream for a specific event type.

**Type Parameters:**
- `T`: Expected payload type (default: `dynamic`)
  - Explicitly specifying the type is recommended for type safety
  - Events with mismatched types are automatically skipped

**Parameters:**
- `eventType` (String): Event type to subscribe to

**Returns:** `Stream<T>` - Stream containing only the payload (cast to type `T`)

**Throws:**
- `ArgumentError`: If eventType is empty

**Examples:**
```dart
// With Generic type (recommended)
InterIsolateEventChannel.on<Map<String, dynamic>>('user.login').listen((payload) {
  String userId = payload['userId']; // Type safe
});

// Without Generic
InterIsolateEventChannel.on('user.login').listen((payload) {
  // payload is dynamic
});
```

## Limitations

- Only supports communication within the same process (no cross-process support)
- Event payloads must be JSON-serializable (Map, List, String, int, double, bool, null)
- No event acknowledgement support
- Broadcast-only (cannot target specific recipients)

## Troubleshooting

### Events Not Being Received

1. Ensure `on()` subscription is set up before calling `emit()`
2. Verify event type strings match exactly (case-sensitive)
3. Confirm payload is JSON-serializable

### Preventing Memory Leaks

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = InterIsolateEventChannel.on('my.event').listen((data) {
      // Handle event
    });
  }

  @override
  void dispose() {
    _subscription?.cancel(); // Always cancel!
    super.dispose();
  }
}
```

## Contributing

Bug reports, feature requests, and pull requests are welcome!

Visit the [GitHub repository](https://github.com/minseok-joel/inter_isolate_event_channel) to submit issues or contribute.

## License

This project is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author

Minseok Joel

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
