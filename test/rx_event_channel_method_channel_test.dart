import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_event_channel/rx_event_channel_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelRxEventChannel platform = MethodChannelRxEventChannel();
  const MethodChannel channel = MethodChannel('rx_event_channel');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('methodChannel is initialized correctly', () {
    expect(platform.methodChannel, isNotNull);
    expect(platform.methodChannel.name, 'rx_event_channel');
  });
}
