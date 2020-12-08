/**
 * Copyright 2020 Jason C.H <ctrysbita@outlook.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.xdea.flutter_native_channel

import io.flutter.Log
import java.nio.ByteBuffer
import java.security.MessageDigest

class SynchronizedNativeBinaryMessenger {
    companion object {
        @JvmStatic
        private val TAG = "NativeBinaryMessenger"

        private val messageHandlers = HashMap<Long, SynchronizedBinaryMessageHandler>()

        fun setMessageHandler(channel: String, handler: SynchronizedBinaryMessageHandler?) {
            val channelMd5 = MessageDigest.getInstance("MD5").digest(channel.toByteArray())
            var channelDigest: Long = 0
            for (i in channelMd5.take(8)) {
                channelDigest = channelDigest.shl(8).or(i.toLong())
            }

            if (handler == null) {
                Log.v(TAG, "Removing synchronized handler for channel $channelDigest '$channel'")
                messageHandlers.remove(channelDigest)
            } else {
                Log.v(TAG, "Setting synchronized handler for channel $channelDigest '$channel'")
                messageHandlers[channelDigest] = handler
            }
        }

        /**
         * Call from native to handle message from dart.
         */
        @JvmStatic
        fun handleMessageFromDart(channel: Long, message: ByteBuffer?): ByteBuffer? {
            Log.v(TAG, "Received message from Dart over channel $channel")
            val handler = messageHandlers[channel]
            return if (handler != null) {
                handler.onMessage(message)
            } else {
                Log.v(TAG, "No registered handler for message. Responding to Dart with empty reply message.")
                null
            }
        }
    }
}