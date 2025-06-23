import Flutter
import UIKit

// 모든 isolate/engine 간에 이벤트를 브로드캐스트하는 싱글톤 클래스
class InterIsolateBroadcaster {
  static let shared = InterIsolateBroadcaster()
  
  // 스레드 안전을 위한 직렬 큐
  private let queue = DispatchQueue(label: "com.joel.rx_event_channel.broadcaster")
  
  // 등록된 이벤트 싱크 모음
  private var sinks = NSMutableSet()
  
  private init() {}
  
  // 새 이벤트 싱크 등록
  func addSink(_ sink: @escaping FlutterEventSink) {
    queue.sync {
      sinks.add(sink)
    }
  }
  
  // 모든 등록된 싱크에 이벤트 브로드캐스트
  func broadcastEvent(_ event: [String: Any]) {
    queue.sync {
      // Swift에서는 NSMutableSet을 반복하면서 요소를 제거할 수 없으므로
      // 별도의 배열에 모든 싱크를 복사한 후 작업
      let allSinks = sinks.allObjects
      
      for case let sink as FlutterEventSink in allSinks {
        // 메인 큐에서 이벤트 전송
        DispatchQueue.main.async {
          sink(event)
        }
      }
    }
  }
}

public class RxEventChannelPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = RxEventChannelPlugin()
    
    // 이벤트 발생용 메서드 채널
    let emitChannel = FlutterMethodChannel(name: "inter_isolate_event/emit", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: emitChannel)
    
    // 브로드캐스트 이벤트 채널
    let eventChannel = FlutterEventChannel(name: "inter_isolate_event/broadcast", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "emitEvent", let args = call.arguments as? [String: Any] {
      guard let eventType = args["eventType"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "eventType is required", details: nil))
        return
      }
      
      let payload = args["payload"]
      let event: [String: Any] = [
        "eventType": eventType,
        "payload": payload as Any
      ]
      
      InterIsolateBroadcaster.shared.broadcastEvent(event)
      result(nil)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - FlutterStreamHandler 메서드
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    InterIsolateBroadcaster.shared.addSink(events)
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    // iOS에서는 싱크가 무효화되면 자동으로 가비지 컬렉션됨
    return nil
  }
}
