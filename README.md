# Inter-Isolate Event Channel

Flutter 멀티엔진/멀티isolate 환경에서 이벤트를 네이티브로 브로드캐스트하여 전체 엔진에 전파하는 이벤트 채널 시스템입니다.

## 기능

- 한 isolate/engine에서 발생한 이벤트를 모든 다른 isolate/engine에 브로드캐스트
- 이벤트 타입 기반 필터링 지원
- 네이티브 레이어를 통한 이벤트 라우팅
- Android 및 iOS 플랫폼 지원

## 설치

`pubspec.yaml`에 다음을 추가하세요:

```yaml
dependencies:
  rx_event_channel: ^0.0.1
```

## 사용 방법

### 이벤트 발생

```dart
import 'package:rx_event_channel/rx_event_channel.dart';

// 이벤트 발생
await InterIsolateEventChannel.emit('call.invite', {'callerId': 'abc123'});
```

### 이벤트 구독

```dart
import 'package:rx_event_channel/rx_event_channel.dart';

// 특정 이벤트 타입 구독
InterIsolateEventChannel.on('call.invite').listen((payload) {
  print('초대 수신: $payload');
});

// 모든 이벤트 구독
InterIsolateEventChannel.onAll.listen((event) {
  print('이벤트 수신: ${event['eventType']} - ${event['payload']}');
});
```

## 작동 방식

1. 이벤트 발생: `MethodChannel('inter_isolate_event/emit')`을 통해 네이티브 레이어로 이벤트 전송
2. 네이티브 브로드캐스트: 싱글톤 브로드캐스터가 모든 등록된 이벤트 싱크에 이벤트 전달
3. 이벤트 수신: `EventChannel('inter_isolate_event/broadcast')`를 통해 각 isolate/engine에서 이벤트 수신
4. 필터링: Dart 레이어에서 이벤트 타입에 따라 필터링

## 주의사항

- 이벤트 싱크 메모리 누수 방지를 위해 구독 취소 시 적절한 정리 필요
- 이벤트 페이로드는 JSON 직렬화 가능한 데이터 구조여야 함
- 현재는 동일 프로세스 내 isolate/engine 간 통신만 지원

## 향후 개발 계획

- 이벤트 확인(acknowledgement) 지원
- 특정 대상(들)에게만 이벤트 발생 기능
- 멀티 프로세스 IPC 지원 (공유 메모리 또는 파일 잠금 기반)
- isolate 간 직접 메시징 폴백 구조 추가

## 라이선스

MIT
