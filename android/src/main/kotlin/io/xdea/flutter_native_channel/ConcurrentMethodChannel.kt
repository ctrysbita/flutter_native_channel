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

import androidx.annotation.UiThread
import io.flutter.Log
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler
import io.flutter.plugin.common.BinaryMessenger.BinaryReply
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCodec
import io.flutter.plugin.common.StandardMethodCodec
import java.io.PrintWriter
import java.io.StringWriter
import java.io.Writer
import java.nio.ByteBuffer
import java.security.MessageDigest

/**
 * A named channel for communicating with the Flutter application using concurrent method calls.
 *
 *
 * Incoming method calls are decoded from binary on receipt, and Java results are encoded into
 * binary before being transmitted back to Flutter. The [MethodCodec] used must be compatible
 * with the one used by the Flutter application. This can be achieved by creating a [MethodChannel](https://docs.flutter.io/flutter/services/MethodChannel-class.html)
 * counterpart of this channel on the Dart side. The Java type of method call arguments and results
 * is `Object`, but only values supported by the specified [MethodCodec] can be used.
 *
 *
 * The logical identity of the channel is given by its name. Identically named channels will
 * interfere with each other's communication.
 */
class ConcurrentMethodChannel constructor(val name: String,
                                          private var id: Long? = null,
                                          private val codec: MethodCodec? = StandardMethodCodec.INSTANCE) {

    init {
        if (id == null) {
            val channelMd5 = MessageDigest.getInstance("MD5").digest(name.toByteArray())
            var channelDigest: Long = 0
            for (i in channelMd5.take(8)) {
                channelDigest = channelDigest.shl(8).or(i.toLong())
            }
            id = channelDigest
        }
    }

    companion object {
        private const val TAG = "ConcurrentMethodChannel#"
    }

    /**
     * Registers a method call handler on this channel.
     *
     * Overrides any existing handler registration for (the name of) this channel.
     *
     * If no handler has been registered, any incoming method call on this channel will be handled
     * silently by sending a null reply. This results in a [MissingPluginException](https://docs.flutter.io/flutter/services/MissingPluginException-class.html)
     * on the Dart side, unless an [OptionalMethodChannel](https://docs.flutter.io/flutter/services/OptionalMethodChannel-class.html)
     * is used.
     *
     * @param handler a [MethodChannel.MethodCallHandler], or null to deregister.
     */
    @UiThread
    fun setMethodCallHandler(handler: MethodChannel.MethodCallHandler?) {
        val msgHandler = if (handler == null) null else IncomingMethodCallHandler(handler)
        ConcurrentNativeBinaryMessenger.setMessageHandler(id!!, msgHandler)
    }

    private inner class IncomingMethodCallHandler constructor(
            private val handler: MethodChannel.MethodCallHandler) : BinaryMessageHandler {
        @UiThread
        override fun onMessage(message: ByteBuffer?, reply: BinaryReply) {
            val call = codec!!.decodeMethodCall(message)
            try {
                handler.onMethodCall(
                        call,
                        object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                reply.reply(codec.encodeSuccessEnvelope(result))
                            }

                            override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
                                reply.reply(codec.encodeErrorEnvelope(errorCode, errorMessage, errorDetails))
                            }

                            override fun notImplemented() {
                                reply.reply(null)
                            }
                        }
                )
            } catch (e: RuntimeException) {
                Log.e(TAG + name, "Failed to handle method call", e)
                reply.reply(codec.encodeErrorEnvelopeWithStacktrace(
                        "error",
                        e.message,
                        null,
                        getStackTrace(e)
                ))
            }
        }

        private fun getStackTrace(e: Exception): String {
            val result: Writer = StringWriter()
            e.printStackTrace(PrintWriter(result))
            return result.toString()
        }
    }
}