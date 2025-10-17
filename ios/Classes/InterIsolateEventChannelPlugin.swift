import Flutter
import UIKit

// Singleton class for broadcasting events across all isolates/engines
class InterIsolateBroadcaster {
  static let shared = InterIsolateBroadcaster()

  // Serial queue for thread safety
  private let queue = DispatchQueue(label: "com.joel.inter_isolate_event_channel.broadcaster")

  // Registered event sinks (managed by UUID for precise control)
  private var sinks: [UUID: FlutterEventSink] = [:]

  private init() {}

  // Registers a new event sink - returns UUID for later removal
  func addSink(_ sink: @escaping FlutterEventSink) -> UUID {
    let id = UUID()
    queue.sync {
      sinks[id] = sink
    }
    return id
  }

  // Removes a specific sink (by UUID)
  func removeSink(id: UUID) {
    queue.sync {
      sinks.removeValue(forKey: id)
    }
  }

  // Broadcasts an event to all registered sinks
  func broadcastEvent(_ event: [String: Any]) {
    queue.sync {
      for sink in sinks.values {
        // Send event on main queue
        DispatchQueue.main.async {
          sink(event)
        }
      }
    }
  }
}

public class InterIsolateEventChannelPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var currentSinkId: UUID?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = InterIsolateEventChannelPlugin()

    // Method channel for emitting events
    let emitChannel = FlutterMethodChannel(name: "inter_isolate_event/emit", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: emitChannel)

    // Event channel for broadcasting
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

  // MARK: - FlutterStreamHandler methods
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    // Store returned UUID for later removal
    currentSinkId = InterIsolateBroadcaster.shared.addSink(events)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    // Remove sink by UUID to prevent memory leaks
    if let id = currentSinkId {
      InterIsolateBroadcaster.shared.removeSink(id: id)
      currentSinkId = nil
    }
    return nil
  }
}
