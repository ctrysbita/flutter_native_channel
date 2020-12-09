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

class SynchronousNativeBinaryMessenger {
    companion object {
        @JvmStatic
        private val TAG = "SynchronousNativeBinaryMessenger#"

        private val messageHandlers = HashMap<Long, SynchronousBinaryMessageHandler>()

        fun setMessageHandler(channel: Long, handler: SynchronousBinaryMessageHandler?) {
            if (handler == null) {
                Log.v(TAG, "Removing synchronous handler for channel $channel")
                messageHandlers.remove(channel)
            } else {
                Log.v(TAG, "Setting synchronous handler for channel $channel")
                messageHandlers[channel] = handler
            }
        }

        /**
         * Call from native to handle message from dart.
         *
         * The message will be freed after return. DO NOT return message itself without copy.
         */
        @JvmStatic
        private fun handleMessageFromDart(channel: Long, message: ByteBuffer?): ByteBuffer? {
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