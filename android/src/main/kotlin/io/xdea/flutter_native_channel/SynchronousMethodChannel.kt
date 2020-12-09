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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodCodec
import io.flutter.plugin.common.StandardMethodCodec
import java.io.PrintWriter
import java.io.StringWriter
import java.io.Writer
import java.nio.ByteBuffer


/**
 * A named channel for communicating with the Flutter application using synchronous method calls.
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
class SynchronousMethodChannel
@JvmOverloads
constructor(private val name: String,
            private val codec: MethodCodec = StandardMethodCodec.INSTANCE) {

    companion object {
        private const val TAG = "SynchronousMethodChannel#"
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
     * @param handler a [MethodCallHandler], or null to deregister.
     */
    @UiThread
    fun setMethodCallHandler(handler: MethodCallHandler?) {
        SynchronousNativeBinaryMessenger.setMessageHandler(
                name, if (handler == null) null else IncomingMethodCallHandler(handler))
    }


    /** A handler of incoming method calls. */
    interface MethodCallHandler {
        /**
         * Handles the specified method call received from Flutter.
         *
         * Handler implementations must return a result for all incoming calls. Failure to do so
         * will result in lingering Flutter result handlers. Calls to unknown or unimplemented
         * methods should be handled using [SynchronousResult.notImplemented].
         *
         * Any uncaught exception thrown by this method will be caught by the channel implementation
         * and logged, and an error result will be sent back to Flutter.
         *
         * @param call A [MethodCall].
         * @return A [SynchronousResult] used for submitting the result of the call.
         */
        fun onMethodCall(call: MethodCall): SynchronousResult
    }

    private inner class IncomingMethodCallHandler
    constructor(private val handler: MethodCallHandler) : SynchronousBinaryMessageHandler {
        @UiThread
        override fun onMessage(message: ByteBuffer?): ByteBuffer? {
            val call = codec.decodeMethodCall(message)
            return try {
                handler.onMethodCall(call).encodeEnvelope(codec)
            } catch (e: RuntimeException) {
                Log.e(TAG + name, "Failed to handle method call", e)
                codec.encodeErrorEnvelopeWithStacktrace(
                        "error",
                        e.message,
                        null,
                        getStackTrace(e)
                )
            }
        }

        private fun getStackTrace(e: Exception): String {
            val result: Writer = StringWriter()
            e.printStackTrace(PrintWriter(result))
            return result.toString()
        }
    }

}