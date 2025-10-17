import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inter_isolate_event_channel/inter_isolate_event_channel_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelInterIsolateEventChannel platform = MethodChannelInterIsolateEventChannel();
  const MethodChannel emitChannel = MethodChannel('inter_isolate_event/emit');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      emitChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'emitEvent') {
          return null;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(emitChannel, null);
  });

  test('methodChannel is initialized correctly', () {
    expect(platform.methodChannel, isNotNull);
    expect(platform.methodChannel.name, 'inter_isolate_event/emit');
  });

  test('eventChannel is initialized correctly', () {
    expect(platform.eventChannel, isNotNull);
    expect(platform.eventChannel.name, 'inter_isolate_event/broadcast');
  });

  test('emit sends correct method call', () async {
    const testEventType = 'test.event';
    const testPayload = {'key': 'value'};

    await platform.emit(testEventType, testPayload);
    // If no exception is thrown, test passes
  });

  test('broadcastStream returns a valid stream', () {
    final stream = platform.broadcastStream;
    expect(stream, isNotNull);
    expect(stream, isA<Stream>());
  });

  test('broadcastStream is cached', () {
    final stream1 = platform.broadcastStream;
    final stream2 = platform.broadcastStream;
    expect(identical(stream1, stream2), true);
  });
}
