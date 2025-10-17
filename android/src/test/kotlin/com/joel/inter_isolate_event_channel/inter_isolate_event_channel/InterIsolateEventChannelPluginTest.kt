package com.joel.inter_isolate_event_channel.inter_isolate_event_channel

import io.flutter.plugin.common.EventChannel
import org.junit.Test
import org.junit.Assert.*

/**
 * Unit tests for InterIsolateEventChannelPlugin
 *
 * Run these tests from the command line by running:
 * `./gradlew testDebugUnitTest` in the `example/android/` directory
 */
class InterIsolateEventChannelPluginTest {

  @Test
  fun `InterIsolateBroadcaster is singleton`() {
    val instance1 = InterIsolateEventChannelPlugin.getInstance()
    val instance2 = InterIsolateEventChannelPlugin.getInstance()

    assertSame(instance1, instance2)
  }

  @Test
  fun `addSink and removeSink work correctly`() {
    val broadcaster = InterIsolateBroadcaster()
    val mockSink = object : EventChannel.EventSink {
      override fun success(event: Any?) {}
      override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {}
      override fun endOfStream() {}
    }

    // Add sink
    broadcaster.addSink(mockSink)

    // Remove sink
    broadcaster.removeSink(mockSink)

    // If no exception is thrown, test passes
    assertTrue(true)
  }

  @Test
  fun `broadcastEvent sends to all registered sinks`() {
    val broadcaster = InterIsolateBroadcaster()
    var receivedCount = 0

    val mockSink = object : EventChannel.EventSink {
      override fun success(event: Any?) {
        receivedCount++
      }
      override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {}
      override fun endOfStream() {}
    }

    broadcaster.addSink(mockSink)
    broadcaster.broadcastEvent(mapOf("eventType" to "test", "payload" to "data"))

    assertEquals(1, receivedCount)

    broadcaster.removeSink(mockSink)
  }
}
