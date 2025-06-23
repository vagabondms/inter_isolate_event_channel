import 'package:flutter/services.dart';

class InterIsolateEventChannel {
  static const MethodChannel _emitChannel =
      MethodChannel('inter_isolate_event/emit');
  static const EventChannel _broadcastChannel =
      EventChannel('inter_isolate_event/broadcast');
  static final Stream<dynamic> _broadcastStream =
      _broadcastChannel.receiveBroadcastStream();

  /// 이벤트를 모든 isolate/engine에 브로드캐스트합니다.
  ///
  /// [eventType] - 이벤트 유형 (예: 'call.invite')
  /// [payload] - 이벤트와 함께 전송할 데이터
  static Future<void> emit(String eventType, dynamic payload) async {
    await _emitChannel.invokeMethod('emitEvent', {
      'eventType': eventType,
      'payload': payload,
    });
  }

  /// 특정 이벤트 유형에 대한 스트림을 반환합니다.
  ///
  /// [eventType] - 구독할 이벤트 유형 (예: 'call.invite')
  static Stream<dynamic> on(String eventType) {
    return _broadcastStream.where((event) {
      if (event is Map && event['eventType'] == eventType) {
        return true;
      }
      return false;
    }).map((event) => event['payload']);
  }

  /// 모든 이벤트에 대한 스트림을 반환합니다.
  static Stream<Map<String, dynamic>> get onAll {
    return _broadcastStream.cast<Map<String, dynamic>>();
  }
}
