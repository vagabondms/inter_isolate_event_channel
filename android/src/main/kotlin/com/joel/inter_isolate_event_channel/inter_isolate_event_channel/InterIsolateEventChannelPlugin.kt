package com.joel.inter_isolate_event_channel.inter_isolate_event_channel

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.CopyOnWriteArraySet

/** InterIsolateEventChannelPlugin */
class InterIsolateEventChannelPlugin: FlutterPlugin, EventChannel.StreamHandler {
  // Event channel for broadcasting
  private lateinit var eventChannel: EventChannel
  // Method channel for emitting events
  private lateinit var emitChannel: MethodChannel
  // Current registered sink (for removal on cancel)
  private var currentSink: EventChannel.EventSink? = null

  // Singleton instance management
  companion object {
    private val instance = InterIsolateBroadcaster()

    fun getInstance(): InterIsolateBroadcaster {
      return instance
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // Method channel for emitting events
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

    // Event channel for broadcasting
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "inter_isolate_event/broadcast")
    eventChannel.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    emitChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  // EventChannel.StreamHandler implementation
  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    events?.let {
      currentSink = it
      getInstance().addSink(it)
    }
  }

  override fun onCancel(arguments: Any?) {
    // Explicitly remove sink to prevent memory leaks
    currentSink?.let {
      getInstance().removeSink(it)
      currentSink = null
    }
  }
}

/**
 * Singleton class for broadcasting events across all isolates/engines
 */
class InterIsolateBroadcaster {
  // Thread-safe event sink collection
  private val sinks = CopyOnWriteArraySet<EventChannel.EventSink>()

  /**
   * Registers a new event sink
   */
  fun addSink(sink: EventChannel.EventSink) {
    sinks.add(sink)
  }

  /**
   * Removes an event sink
   */
  fun removeSink(sink: EventChannel.EventSink) {
    sinks.remove(sink)
  }

  /**
   * Broadcasts an event to all registered sinks
   */
  fun broadcastEvent(event: Map<String, Any?>) {
    // Send event to all sinks
    val iterator = sinks.iterator()
    while (iterator.hasNext()) {
      val sink = iterator.next()
      try {
        sink.success(event)
      } catch (e: Exception) {
        // Remove failed sinks immediately (CopyOnWriteArraySet allows removal during iteration)
        sinks.remove(sink)
      }
    }
  }
}
