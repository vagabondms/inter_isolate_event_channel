import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inter_isolate_event_channel/inter_isolate_event_channel.dart';
import 'package:inter_isolate_event_channel/inter_isolate_event_channel_platform_interface.dart';
import 'package:inter_isolate_event_channel/inter_isolate_event_channel_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockInterIsolateEventChannelPlatform
    with MockPlatformInterfaceMixin
    implements InterIsolateEventChannelPlatform {
  final StreamController<dynamic> _controller = StreamController.broadcast();
  final List<Map<String, dynamic>> emittedEvents = [];

  @override
  Future<void> emit(String eventType, dynamic payload) async {
    final event = {
      'eventType': eventType,
      'payload': payload,
    };
    emittedEvents.add(event);
    _controller.add(event);
  }

  @override
  Stream<dynamic> get broadcastStream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  final InterIsolateEventChannelPlatform initialPlatform =
      InterIsolateEventChannelPlatform.instance;

  test('$MethodChannelInterIsolateEventChannel is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelInterIsolateEventChannel>());
  });

  group('InterIsolateEventChannel', () {
    late MockInterIsolateEventChannelPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockInterIsolateEventChannelPlatform();
      InterIsolateEventChannelPlatform.instance = mockPlatform;
    });

    tearDown(() {
      mockPlatform.dispose();
      InterIsolateEventChannelPlatform.instance = MethodChannelInterIsolateEventChannel();
    });

    test('emit sends event with correct eventType and payload', () async {
      const eventType = 'test.event';
      const payload = {'key': 'value'};

      await InterIsolateEventChannel.emit(eventType, payload);

      expect(mockPlatform.emittedEvents.length, 1);
      expect(mockPlatform.emittedEvents[0]['eventType'], eventType);
      expect(mockPlatform.emittedEvents[0]['payload'], payload);
    });

    test('emit throws ArgumentError when eventType is empty', () async {
      expect(
        () => InterIsolateEventChannel.emit('', {'key': 'value'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    group('JSON serialization validation', () {
      test('emit accepts null payload', () async {
        await InterIsolateEventChannel.emit('test.event', null);
        expect(mockPlatform.emittedEvents.last['payload'], null);
      });

      test('emit accepts primitive types', () async {
        await InterIsolateEventChannel.emit('test.bool', true);
        await InterIsolateEventChannel.emit('test.int', 42);
        await InterIsolateEventChannel.emit('test.double', 3.14);
        await InterIsolateEventChannel.emit('test.string', 'hello');

        expect(mockPlatform.emittedEvents[0]['payload'], true);
        expect(mockPlatform.emittedEvents[1]['payload'], 42);
        expect(mockPlatform.emittedEvents[2]['payload'], 3.14);
        expect(mockPlatform.emittedEvents[3]['payload'], 'hello');
      });

      test('emit accepts List with JSON-serializable values', () async {
        const payload = [1, 'two', true, null];
        await InterIsolateEventChannel.emit('test.list', payload);
        expect(mockPlatform.emittedEvents.last['payload'], payload);
      });

      test('emit accepts Map with String keys and JSON-serializable values', () async {
        const payload = {
          'number': 42,
          'text': 'hello',
          'flag': true,
          'nothing': null,
        };
        await InterIsolateEventChannel.emit('test.map', payload);
        expect(mockPlatform.emittedEvents.last['payload'], payload);
      });

      test('emit accepts nested List and Map', () async {
        const payload = {
          'users': [
            {'name': 'Alice', 'age': 30},
            {'name': 'Bob', 'age': 25},
          ],
          'metadata': {
            'count': 2,
            'tags': ['active', 'verified'],
          },
        };
        await InterIsolateEventChannel.emit('test.nested', payload);
        expect(mockPlatform.emittedEvents.last['payload'], payload);
      });

      test('emit throws ArgumentError for non-JSON-serializable types', () {
        expect(
          () => InterIsolateEventChannel.emit('test.event', DateTime.now()),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('must be JSON-serializable'),
            ),
          ),
        );
      });

      test('emit throws ArgumentError for List with non-JSON-serializable elements', () {
        expect(
          () => InterIsolateEventChannel.emit('test.event', [1, DateTime.now()]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('emit throws ArgumentError for Map with non-String keys', () {
        expect(
          () => InterIsolateEventChannel.emit('test.event', {1: 'value'}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('emit throws ArgumentError for Map with non-JSON-serializable values', () {
        expect(
          () => InterIsolateEventChannel.emit('test.event', {'key': DateTime.now()}),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    test('on filters events by eventType', () async {
      const targetEventType = 'call.invite';
      const otherEventType = 'message.new';
      const targetPayload = {'caller': 'Alice'};
      const otherPayload = {'message': 'Hello'};

      final events = <dynamic>[];
      final subscription =
          InterIsolateEventChannel.on(targetEventType).listen(events.add);

      await InterIsolateEventChannel.emit(targetEventType, targetPayload);
      await InterIsolateEventChannel.emit(otherEventType, otherPayload);
      await InterIsolateEventChannel.emit(targetEventType, targetPayload);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, 2);
      expect(events[0], targetPayload);
      expect(events[1], targetPayload);

      await subscription.cancel();
    });

    test('on returns only payload, not full event', () async {
      const eventType = 'test.event';
      const payload = {'key': 'value'};

      dynamic receivedData;
      final subscription = InterIsolateEventChannel.on(eventType).listen((data) {
        receivedData = data;
      });

      await InterIsolateEventChannel.emit(eventType, payload);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedData, payload);
      expect(receivedData is Map, true);
      expect((receivedData as Map).containsKey('eventType'), false);

      await subscription.cancel();
    });

    test('on throws ArgumentError when eventType is empty', () {
      expect(
        () => InterIsolateEventChannel.on(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('multiple listeners receive the same event', () async {
      const eventType = 'broadcast.test';
      const payload = {'data': 'shared'};

      final events1 = <dynamic>[];
      final events2 = <dynamic>[];

      final sub1 = InterIsolateEventChannel.on(eventType).listen(events1.add);
      final sub2 = InterIsolateEventChannel.on(eventType).listen(events2.add);

      await InterIsolateEventChannel.emit(eventType, payload);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(events1.length, 1);
      expect(events2.length, 1);
      expect(events1[0], payload);
      expect(events2[0], payload);

      await sub1.cancel();
      await sub2.cancel();
    });

    group('Generic type safety', () {
      test('on<Map> receives Map payload with correct type', () async {
        const eventType = 'user.login';
        const payload = {'userId': '123', 'name': 'Alice'};

        Map<String, dynamic>? receivedPayload;
        final subscription = InterIsolateEventChannel.on<Map<String, dynamic>>(eventType)
            .listen((data) {
          receivedPayload = data;
        });

        await InterIsolateEventChannel.emit(eventType, payload);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedPayload, payload);
        expect(receivedPayload!['userId'], '123');
        expect(receivedPayload!['name'], 'Alice');

        await subscription.cancel();
      });

      test('on<String> receives String payload with correct type', () async {
        const eventType = 'message.text';
        const payload = 'Hello, World!';

        String? receivedPayload;
        final subscription = InterIsolateEventChannel.on<String>(eventType)
            .listen((data) {
          receivedPayload = data;
        });

        await InterIsolateEventChannel.emit(eventType, payload);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedPayload, payload);
        expect(receivedPayload!.length, 13);

        await subscription.cancel();
      });

      test('on<int> receives int payload with correct type', () async {
        const eventType = 'counter.update';
        const payload = 42;

        int? receivedPayload;
        final subscription = InterIsolateEventChannel.on<int>(eventType)
            .listen((data) {
          receivedPayload = data;
        });

        await InterIsolateEventChannel.emit(eventType, payload);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedPayload, payload);
        expect(receivedPayload! * 2, 84);

        await subscription.cancel();
      });

      test('on<List> receives List payload with correct type', () async {
        const eventType = 'tags.updated';
        const payload = ['dart', 'flutter', 'mobile'];

        List<dynamic>? receivedPayload;
        final subscription = InterIsolateEventChannel.on<List<dynamic>>(eventType)
            .listen((data) {
          receivedPayload = data;
        });

        await InterIsolateEventChannel.emit(eventType, payload);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedPayload, payload);
        expect(receivedPayload!.length, 3);
        expect(receivedPayload![0], 'dart');

        await subscription.cancel();
      });

      test('on<T> skips events with mismatched payload type', () async {
        const eventType = 'mixed.event';

        final stringEvents = <String>[];
        final intEvents = <int>[];

        final stringSub = InterIsolateEventChannel.on<String>(eventType)
            .listen(stringEvents.add);
        final intSub = InterIsolateEventChannel.on<int>(eventType)
            .listen(intEvents.add);

        await InterIsolateEventChannel.emit(eventType, 'text');
        await InterIsolateEventChannel.emit(eventType, 42);
        await InterIsolateEventChannel.emit(eventType, 'more text');
        await InterIsolateEventChannel.emit(eventType, 100);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(stringEvents.length, 2);
        expect(stringEvents[0], 'text');
        expect(stringEvents[1], 'more text');

        expect(intEvents.length, 2);
        expect(intEvents[0], 42);
        expect(intEvents[1], 100);

        await stringSub.cancel();
        await intSub.cancel();
      });

      test('on without generic accepts dynamic type', () async {
        const eventType = 'dynamic.event';
        const payload1 = 'text';
        const payload2 = 42;
        const payload3 = {'key': 'value'};

        final events = <dynamic>[];
        final subscription = InterIsolateEventChannel.on(eventType)
            .listen(events.add);

        await InterIsolateEventChannel.emit(eventType, payload1);
        await InterIsolateEventChannel.emit(eventType, payload2);
        await InterIsolateEventChannel.emit(eventType, payload3);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, 3);
        expect(events[0], payload1);
        expect(events[1], payload2);
        expect(events[2], payload3);

        await subscription.cancel();
      });

      test('on<bool> receives null payload when T is nullable', () async {
        const eventType = 'nullable.event';

        bool? receivedPayload;
        final subscription = InterIsolateEventChannel.on<bool?>(eventType)
            .listen((data) {
          receivedPayload = data;
        });

        await InterIsolateEventChannel.emit(eventType, null);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(receivedPayload, null);

        await subscription.cancel();
      });
    });
  });
}
