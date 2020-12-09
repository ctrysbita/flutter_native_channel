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

import io.flutter.plugin.common.MethodCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.nio.ByteBuffer

/**
 * Represent result of a method call in [SynchronousMethodChannel].
 */
class SynchronousResult private constructor(private val type: Type) {
    private enum class Type {
        Success,
        Error,
        Unimplemented,
    }

    private var result: Any? = null

    private var errorCode: String? = null
    private var errorMessage: String? = null
    private var errorDetails: Any? = null

    companion object {
        /**
         * Create a successful result.
         *
         * @param result The result, possibly null. The result must be an Object type supported by the
         * codec. For instance, if you are using [StandardMessageCodec] (default), please see
         * its documentation on what types are supported.
         */
        fun success(result: Any?): SynchronousResult {
            return SynchronousResult(Type.Success).apply {
                this.result = result
            }
        }

        /**
         * Create an error result.
         *
         * @param errorCode An error code String.
         * @param errorMessage A human-readable error message String, possibly null.
         * @param errorDetails Error details, possibly null. The details must be an Object type
         * supported by the codec. For instance, if you are using [StandardMessageCodec]
         * (default), please see its documentation on what types are supported.
         */
        fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?): SynchronousResult {
            return SynchronousResult(Type.Error).apply {
                this.errorCode = errorCode
                this.errorMessage = errorMessage
                this.errorDetails = errorDetails
            }
        }

        /** Create a call to an unimplemented method. */
        fun notImplemented(): SynchronousResult {
            return SynchronousResult(Type.Unimplemented)
        }
    }

    /**
     * Encode result using given [MethodCodec].
     */
    fun encodeEnvelope(codec: MethodCodec): ByteBuffer? {
        return when (type) {
            Type.Success -> codec.encodeSuccessEnvelope(result)
            Type.Error -> codec.encodeErrorEnvelope(errorCode, errorMessage, errorDetails)
            else -> null
        }
    }
}