package io.xdea.flutter_native_channel

import io.flutter.Log
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler
import io.flutter.plugin.common.BinaryMessenger.BinaryReply
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

class ConcurrentNativeBinaryMessenger {
    companion object {
        @JvmStatic
        private val TAG = "SynchronousNativeBinaryMessenger#"

        private val messageHandlers = HashMap<Long, BinaryMessageHandler>()

        fun setMessageHandler(channel: Long, handler: BinaryMessageHandler?) {
            if (handler == null) {
                Log.v(TAG, "Removing asynchronous handler for channel $channel")
                messageHandlers.remove(channel)
            } else {
                Log.v(TAG, "Setting asynchronous handler for channel $channel")
                messageHandlers[channel] = handler
            }
        }

        /**
         * Call from native to handle asynchronous message from dart.
         *
         * The message will be freed and become no longer available after reply. DO NOT reply
         * message itself without copy.
         */
        @JvmStatic
        private fun handleMessageFromDart(channel: Long, message: ByteBuffer?, seq: Long) {
            Log.v(TAG, "Received message from Dart over channel $channel")
            val handler = messageHandlers[channel]
            if (handler != null) {
                try {
                    Log.v(TAG, "Deferring to registered handler to process message.")
                    handler.onMessage(message, Reply(seq, message))
                } catch (ex: Exception) {
                    Log.e(TAG, "Uncaught exception in binary message listener", ex)
                    replyMessageToDart(seq, null, message)
                }
            } else {
                Log.v(TAG, "No registered handler for message. Responding to Dart with empty reply message.")
                replyMessageToDart(seq, null, message)
            }
        }

        @JvmStatic
        private external fun replyMessageToDart(replyId: Long, reply: ByteBuffer?, message: ByteBuffer?)
    }

    internal class Reply(private val replyId: Long, private val message: ByteBuffer?) : BinaryReply {
        private val done = AtomicBoolean(false)

        override fun reply(reply: ByteBuffer?) {
            check(!done.getAndSet(true)) { "Reply already submitted" }
            replyMessageToDart(replyId, reply, message)
        }
    }
}