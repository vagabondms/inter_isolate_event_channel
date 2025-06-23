// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rx_event_channel/rx_event_channel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InterIsolateEventChannel initialization test',
      (WidgetTester tester) async {
    // 이벤트 채널이 초기화되는지 확인
    expect(InterIsolateEventChannel.on('test.event'), isA<Stream>());
    expect(InterIsolateEventChannel.onAll, isA<Stream>());

    // emit 메서드가 예외 없이 실행되는지 확인
    await expectLater(
      () => InterIsolateEventChannel.emit('test.event', {'test': 'data'}),
      returnsNormally,
    );
  });
}
