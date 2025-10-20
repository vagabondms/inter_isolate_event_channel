## 1.0.2

### Maintenance

* Version bump

## 1.0.1

### Documentation

* **README**: Translated all Korean content to English for international accessibility
* **Documentation**: Removed "Future Development" section from README

## 1.0.0

### 🎉 First Stable Release

Flutter 멀티엔진/멀티 isolate 환경에서 이벤트를 브로드캐스트하는 프로덕션 준비 완료 플러그인

#### 🔄 Breaking Changes
* **패키지명 변경**: `rx_event_channel` → `inter_isolate_event_channel`
  - RxDart와의 혼동을 피하고 패키지의 목적을 명확히 하기 위해 변경
  - 모든 import 경로 업데이트 필요: `package:inter_isolate_event_channel/inter_isolate_event_channel.dart`

#### ✨ 주요 기능
* 한 isolate/engine에서 발생한 이벤트를 모든 다른 isolate/engine에 브로드캐스트
* 이벤트 타입 기반 필터링 지원
* **타입 안전성**: Generic을 통한 컴파일 타임 타입 체크
* **JSON 직렬화 검증**: emit 시점에 페이로드 자동 검증
* Android 및 iOS 플랫폼 지원
* 네이티브 레이어를 통한 효율적인 이벤트 라우팅
* 메모리 누수 방지를 위한 적절한 리소스 관리

#### 🔧 주요 개선사항
* **타입 안전성 개선**:
  - `on<T>()` 메서드에 Generic 타입 파라미터 추가
  - 타입 불일치 이벤트는 자동 스킵 (관대 모드)
  - 개발 모드에서 타입 불일치 경고 출력
* **JSON 직렬화 검증**:
  - `emit()` 시점에 페이로드 타입 검증
  - 지원 타입: null, bool, num, String, List, Map
  - 재귀적 검증으로 중첩 구조 지원
  - 잘못된 타입 전달 시 명확한 에러 메시지
* **메모리 관리 강화**: iOS/Android 모두 onCancel 시 싱크 명시적 제거
* **Platform Interface 패턴**: 올바른 Flutter 플러그인 아키텍처 준수
* **포괄적인 에러 처리**: ArgumentError, PlatformException 처리
* **완전한 테스트 커버리지**: 28개 단위 테스트 포함
  - JSON 직렬화 검증 테스트 10개
  - Generic 타입 안전성 테스트 7개
* **전문적인 문서화**: 상세한 README, API 레퍼런스, 사용 예제

#### 📱 플랫폼
* **Android**: API 레벨 지원, CopyOnWriteArraySet 사용한 thread-safe 구현
* **iOS**: iOS 12.0+, Weak reference 패턴으로 메모리 누수 방지

#### 📖 API
* `InterIsolateEventChannel.emit(String eventType, dynamic payload)` - 이벤트 발생
  - JSON 직렬화 검증 포함
  - 잘못된 타입 전달 시 ArgumentError 발생
* `InterIsolateEventChannel.on<T>(String eventType)` - 특정 타입의 이벤트 구독
  - Generic 타입 파라미터로 타입 안전성 확보
  - 타입 불일치 이벤트 자동 필터링

#### ⚠️ 알려진 제약사항
* 동일 프로세스 내 isolate/engine 간 통신만 지원 (크로스 프로세스 미지원)
* 이벤트 페이로드는 JSON 직렬화 가능한 타입이어야 함
* 이벤트 전달 확인(acknowledgement) 미지원
* 브로드캐스트 방식이므로 특정 대상만 지정 불가

#### 🔮 향후 계획
* 이벤트 확인(acknowledgement) 지원
* 특정 대상(들)에게만 이벤트 발송 기능
* 멀티 프로세스 IPC 지원
* 이벤트 우선순위 및 큐잉
