# inter_isolate_event_channel

[![pub package](https://img.shields.io/pub/v/inter_isolate_event_channel.svg)](https://pub.dev/packages/inter_isolate_event_channel)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Flutter 멀티엔진/멀티 isolate 환경에서 이벤트를 네이티브 레이어를 통해 브로드캐스트하여 전체 엔진에 전파하는 이벤트 채널 플러그인입니다.

## 주요 기능

- ✅ 한 isolate/engine에서 발생한 이벤트를 모든 다른 isolate/engine에 브로드캐스트
- ✅ 이벤트 타입 기반 필터링 지원
- ✅ **타입 안전성**: Generic을 통한 컴파일 타임 타입 체크
- ✅ **JSON 직렬화 검증**: emit 시점에 페이로드 검증
- ✅ 네이티브 레이어(Android/iOS)를 통한 효율적인 이벤트 라우팅
- ✅ 메모리 누수 방지를 위한 적절한 리소스 관리
- ✅ Platform Interface 패턴 준수
- ✅ 포괄적인 에러 처리

## 사용 사례

이 플러그인은 다음과 같은 상황에서 유용합니다:

- **멀티 엔진 Flutter 앱**: 네이티브 앱 내에 여러 Flutter 엔진이 있는 경우
- **Add-to-App 시나리오**: 기존 네이티브 앱에 Flutter를 통합한 경우
- **백그라운드 isolate 통신**: 백그라운드에서 실행되는 isolate와 UI isolate 간 이벤트 공유
- **실시간 알림**: 한 화면의 이벤트를 다른 모든 화면에 즉시 전파

## 설치

`pubspec.yaml`에 다음을 추가하세요:

```yaml
dependencies:
  inter_isolate_event_channel: ^0.0.1
```

그리고 패키지를 설치합니다:

```bash
flutter pub get
```

## 사용 방법

### 기본 사용법

#### 이벤트 발생

```dart
import 'package:inter_isolate_event_channel/inter_isolate_event_channel.dart';

// 이벤트 발생
await InterIsolateEventChannel.emit(
  'call.invite',
  {'callerId': 'user123', 'callerName': 'Alice'}
);
```

#### 이벤트 구독

```dart
import 'package:inter_isolate_event_channel/inter_isolate_event_channel.dart';

// 특정 이벤트 타입 구독 (Generic으로 타입 안전성 확보)
final subscription = InterIsolateEventChannel.on<Map<String, dynamic>>('call.invite').listen((payload) {
  // payload는 자동으로 Map<String, dynamic> 타입
  print('통화 초대 수신: ${payload['callerName']}');
  final callerId = payload['callerId']; // 타입 안전!
});

// 구독 취소 (메모리 누수 방지)
await subscription.cancel();
```

### 타입 안전성

#### Generic 타입 지정

Generic 타입을 지정하면 컴파일 타임에 타입 체크를 받을 수 있습니다:

```dart
// Map 타입으로 지정
InterIsolateEventChannel.on<Map<String, dynamic>>('user.login').listen((payload) {
  String userId = payload['userId']; // 타입 안전!
  String name = payload['name'];
});

// String 타입으로 지정
InterIsolateEventChannel.on<String>('message.text').listen((message) {
  print(message.toUpperCase()); // String 메서드 사용 가능
});

// int 타입으로 지정
InterIsolateEventChannel.on<int>('counter.update').listen((count) {
  print(count * 2); // int 연산 가능
});

// List 타입으로 지정
InterIsolateEventChannel.on<List<dynamic>>('tags.updated').listen((tags) {
  print(tags.length); // List 메서드 사용 가능
});
```

#### 타입 불일치 처리

타입이 일치하지 않는 이벤트는 자동으로 스킵됩니다:

```dart
// String 타입만 받는 리스너
InterIsolateEventChannel.on<String>('mixed.event').listen((message) {
  print('문자 메시지: $message');
});

// int 타입만 받는 리스너
InterIsolateEventChannel.on<int>('mixed.event').listen((number) {
  print('숫자: $number');
});

// 다양한 타입 발송
await InterIsolateEventChannel.emit('mixed.event', 'Hello'); // String 리스너만 수신
await InterIsolateEventChannel.emit('mixed.event', 42);       // int 리스너만 수신
await InterIsolateEventChannel.emit('mixed.event', {'key': 'value'}); // 둘 다 스킵
```

개발 모드에서는 타입 불일치 시 경고가 출력됩니다.

### 고급 사용 예제

#### 실시간 채팅 메시지 브로드캐스트

```dart
// Engine 1: 메시지 발송
await InterIsolateEventChannel.emit('chat.message', {
  'roomId': 'room123',
  'message': 'Hello!',
  'sender': 'user456',
  'timestamp': DateTime.now().toIso8601String(),
});

// Engine 2, 3, 4...: 메시지 수신 (타입 안전)
InterIsolateEventChannel.on<Map<String, dynamic>>('chat.message').listen((payload) {
  if (payload['roomId'] == currentRoomId) {
    displayMessage(payload['message'], payload['sender']);
  }
});
```

#### 상태 동기화

```dart
// 로그인 상태 변경 브로드캐스트
await InterIsolateEventChannel.emit('auth.login', {
  'userId': 'user789',
  'token': 'jwt_token_here',
});

// 모든 화면에서 로그인 상태 업데이트
InterIsolateEventChannel.on('auth.login').listen((payload) {
  updateAuthState(payload['userId'], payload['token']);
});

// 로그아웃
await InterIsolateEventChannel.emit('auth.logout', null);
```

## 작동 원리

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

1. **이벤트 발생**: `emit()` 메서드가 `MethodChannel`을 통해 네이티브 레이어로 이벤트 전송
2. **네이티브 브로드캐스트**: 싱글톤 브로드캐스터가 모든 등록된 EventSink에 이벤트 전달
3. **이벤트 수신**: 각 isolate가 `EventChannel`을 통해 브로드캐스트 스트림을 구독
4. **필터링**: Dart 레이어에서 `on()` 메서드로 이벤트 타입별 필터링

## API 레퍼런스

### `InterIsolateEventChannel.emit(String eventType, dynamic payload)`

이벤트를 모든 isolate/engine에 브로드캐스트합니다.

**Parameters:**
- `eventType` (String): 이벤트 유형 식별자 (예: 'call.invite', 'message.new')
- `payload` (dynamic): 전송할 데이터 (JSON 직렬화 가능해야 함)
  - 지원 타입: `null`, `bool`, `num` (int, double), `String`, `List`, `Map`
  - `List`와 `Map`은 재귀적으로 검증됩니다
  - `Map`의 키는 반드시 `String`이어야 합니다

**Returns:** `Future<void>`

**Throws:**
- `ArgumentError`: eventType이 비어있거나 payload가 JSON 직렬화 불가능한 경우
- `PlatformException`: 네이티브 플랫폼에서 에러 발생 시

**Examples:**
```dart
// 올바른 페이로드
await InterIsolateEventChannel.emit('event', null);
await InterIsolateEventChannel.emit('event', 'text');
await InterIsolateEventChannel.emit('event', 42);
await InterIsolateEventChannel.emit('event', [1, 2, 3]);
await InterIsolateEventChannel.emit('event', {'key': 'value'});
await InterIsolateEventChannel.emit('event', {
  'nested': {'data': [1, 2, 3]},
  'list': ['a', 'b', 'c'],
});

// 잘못된 페이로드 (ArgumentError 발생)
await InterIsolateEventChannel.emit('event', DateTime.now()); // ❌
await InterIsolateEventChannel.emit('event', MyCustomClass()); // ❌
await InterIsolateEventChannel.emit('event', {1: 'value'}); // ❌ 키가 String이 아님
```

### `InterIsolateEventChannel.on<T>(String eventType)`

특정 이벤트 타입에 대한 스트림을 반환합니다.

**Type Parameters:**
- `T`: payload의 예상 타입 (기본값: `dynamic`)
  - 타입 안전성을 위해 명시적으로 지정하는 것을 권장합니다
  - 타입이 일치하지 않는 이벤트는 자동으로 스킵됩니다

**Parameters:**
- `eventType` (String): 구독할 이벤트 유형

**Returns:** `Stream<T>` - 해당 이벤트의 payload만 포함 (타입 `T`로 캐스팅됨)

**Throws:**
- `ArgumentError`: eventType이 비어있는 경우

**Examples:**
```dart
// Generic 타입 지정 (권장)
InterIsolateEventChannel.on<Map<String, dynamic>>('user.login').listen((payload) {
  String userId = payload['userId']; // 타입 안전
});

// Generic 미지정
InterIsolateEventChannel.on('user.login').listen((payload) {
  // payload는 dynamic
});
```

## 제약사항

- 동일 프로세스 내 isolate/engine 간 통신만 지원 (크로스 프로세스 미지원)
- 이벤트 페이로드는 JSON 직렬화 가능한 타입이어야 함 (Map, List, String, int, double, bool, null)
- 이벤트 전달 확인(acknowledgement) 미지원
- 브로드캐스트 방식이므로 특정 대상만 지정 불가

## 문제 해결

### 이벤트가 수신되지 않는 경우

1. `on()` 구독이 `emit()` 호출 전에 설정되었는지 확인
2. 이벤트 타입 문자열이 정확히 일치하는지 확인 (대소문자 구분)
3. 페이로드가 JSON 직렬화 가능한지 확인

### 메모리 누수 방지

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
      // 이벤트 처리
    });
  }

  @override
  void dispose() {
    _subscription?.cancel(); // 반드시 취소!
    super.dispose();
  }
}
```

## 향후 개발 계획

- [ ] 이벤트 확인(acknowledgement) 지원
- [ ] 특정 대상(들)에게만 이벤트 발송 기능
- [ ] 멀티 프로세스 IPC 지원
- [ ] 이벤트 우선순위 및 큐잉
- [ ] 요청-응답 패턴 지원

## 기여하기

버그 리포트, 기능 제안, 풀 리퀘스트를 환영합니다!

이슈를 제출하거나 기여하려면 [GitHub 저장소](https://github.com/minseok-joel/inter_isolate_event_channel)를 방문해주세요.

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 저자

Minseok Joel

## 변경사항

변경 내역은 [CHANGELOG.md](CHANGELOG.md)를 참조하세요.
