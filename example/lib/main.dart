import 'package:flutter/material.dart';
import 'dart:async';

import 'package:rx_event_channel/rx_event_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _eventLogs = <String>[];
  final _eventController = StreamController<String>();
  String _selectedEventType = 'call.invite';
  final _payloadController = TextEditingController();

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    // 모든 이벤트 구독
    InterIsolateEventChannel.on('call.invite').listen((event) {
      final log = '수신: ${event['eventType']} - ${event['payload']}';
      _eventController.add(log);
    });

    // 이벤트 로그 스트림 리스너
    _eventController.stream.listen((log) {
      setState(() {
        _eventLogs.add(log);
        // 최대 100개 로그만 유지
        if (_eventLogs.length > 100) {
          _eventLogs.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _eventController.close();
    _payloadController.dispose();
    super.dispose();
  }

  // 특정 이벤트 타입 구독
  void _subscribeToEventType(String eventType) {
    _subscription?.cancel();

    _subscription = InterIsolateEventChannel.on(eventType).listen((payload) {
      final log = '구독 이벤트($eventType): $payload';
      _eventController.add(log);
    });

    _eventController.add('$eventType 이벤트 구독 시작');
  }

  // 이벤트 발생
  Future<void> _emitEvent() async {
    final payload = _payloadController.text.isEmpty
        ? {'timestamp': DateTime.now().toIso8601String()}
        : {
            'message': _payloadController.text,
            'timestamp': DateTime.now().toIso8601String()
          };

    try {
      await InterIsolateEventChannel.emit(_selectedEventType, payload);
      _eventController.add('발생: $_selectedEventType - $payload');
      _payloadController.clear();
    } catch (e) {
      _eventController.add('오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('인터 아이솔레이트 이벤트 채널 예제'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이벤트 발생 섹션
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('이벤트 발생',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // 이벤트 타입 선택
                      DropdownButton<String>(
                        value: _selectedEventType,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedEventType = newValue;
                            });
                          }
                        },
                        items: <String>[
                          'call.invite',
                          'message.new',
                          'notification.received',
                          'custom.event'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),

                      // 페이로드 입력
                      TextField(
                        controller: _payloadController,
                        decoration: const InputDecoration(
                          labelText: '페이로드 (메시지)',
                          hintText: '비워두면 기본 타임스탬프만 전송',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 이벤트 발생 버튼
                      ElevatedButton(
                        onPressed: _emitEvent,
                        child: const Text('이벤트 발생'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 이벤트 구독 섹션
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('이벤트 구독',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // 이벤트 타입 선택 및 구독 버튼
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedEventType,
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedEventType = newValue;
                                  });
                                }
                              },
                              items: <String>[
                                'call.invite',
                                'message.new',
                                'notification.received',
                                'custom.event'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () =>
                                _subscribeToEventType(_selectedEventType),
                            child: const Text('구독'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 이벤트 로그
              const Text('이벤트 로그:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _eventLogs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: Text(_eventLogs[_eventLogs.length - 1 - index]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
