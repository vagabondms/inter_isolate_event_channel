package com.joel.rx_event_channel.rx_event_channel

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.CopyOnWriteArraySet

/** RxEventChannelPlugin */
class RxEventChannelPlugin: FlutterPlugin, EventChannel.StreamHandler {
  // 이벤트 채널 (브로드캐스트용)
  private lateinit var eventChannel: EventChannel
  // 이벤트 발생용 메서드 채널
  private lateinit var emitChannel: MethodChannel
  
  // 싱글톤 인스턴스 관리
  companion object {
    private val instance = InterIsolateBroadcaster()
    
    fun getInstance(): InterIsolateBroadcaster {
      return instance
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // 이벤트 발생용 메서드 채널
    emitChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "inter_isolate_event/emit")
    emitChannel.setMethodCallHandler { call, result ->
      if (call.method == "emitEvent") {
        val eventType = call.argument<String>("eventType")
        val payload = call.argument<Any>("payload")
        
        if (eventType != null) {
          val event = mapOf(
            "eventType" to eventType,
            "payload" to payload
          )
          getInstance().broadcastEvent(event)
          result.success(null)
        } else {
          result.error("INVALID_ARGUMENT", "eventType is required", null)
        }
      } else {
        result.notImplemented()
      }
    }
    
    // 브로드캐스트 이벤트 채널
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "inter_isolate_event/broadcast")
    eventChannel.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    emitChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
  
  // EventChannel.StreamHandler 구현
  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    events?.let { 
      getInstance().addSink(it) 
    }
  }
  
  override fun onCancel(arguments: Any?) {
    // 취소 로직 간소화 - Flutter 측에서 구독 취소 시 자동으로 처리됨
    // 실제 싱크 제거는 broadcastEvent에서 예외 발생 시 처리
  }
}

/**
 * 모든 isolate/engine 간에 이벤트를 브로드캐스트하는 싱글톤 클래스
 */
class InterIsolateBroadcaster {
  // Thread-safe한 이벤트 싱크 컬렉션
  private val sinks = CopyOnWriteArraySet<EventChannel.EventSink>()
  
  /**
   * 새 이벤트 싱크 등록
   */
  fun addSink(sink: EventChannel.EventSink) {
    sinks.add(sink)
  }
  
  /**
   * 모든 등록된 싱크에 이벤트 브로드캐스트
   */
  fun broadcastEvent(event: Map<String, Any?>) {
    // 모든 싱크에 이벤트 전송
    for (sink in sinks) {
      try {
        sink.success(event)
      } catch (e: Exception) {
        // 실패한 싱크는 즉시 제거 (CopyOnWriteArraySet은 반복 중 제거 가능)
        sinks.remove(sink)
      }
    }
  }
}
