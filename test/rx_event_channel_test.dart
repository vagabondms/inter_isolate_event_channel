import 'package:flutter_test/flutter_test.dart';
import 'package:rx_event_channel/rx_event_channel.dart';
import 'package:rx_event_channel/rx_event_channel_platform_interface.dart';
import 'package:rx_event_channel/rx_event_channel_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRxEventChannelPlatform
    with MockPlatformInterfaceMixin
    implements RxEventChannelPlatform {}

void main() {
  final RxEventChannelPlatform initialPlatform =
      RxEventChannelPlatform.instance;

  test('$MethodChannelRxEventChannel is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRxEventChannel>());
  });

  test('InterIsolateEventChannel has static methods', () {
    expect(InterIsolateEventChannel.emit, isA<Function>());
    expect(InterIsolateEventChannel.on, isA<Function>());
  });
}
