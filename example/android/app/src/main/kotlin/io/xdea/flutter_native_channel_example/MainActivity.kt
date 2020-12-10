package io.xdea.flutter_native_channel_example

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.xdea.flutter_native_channel.*
import java.nio.ByteBuffer

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var synchronousChannel: SynchronousMethodChannel
    private lateinit var nativeMethodChannel: NativeMethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter_native_channel_example")
        channel.setMethodCallHandler(this)

        // Async, Flutter, Bin
        flutterEngine.dartExecutor.binaryMessenger.setMessageHandler("flutter_bin_channel") { _, reply ->
            reply.reply(ByteBuffer.wrap(ByteArray(1024 * 1024 * 5)))
        }

        // Sync, Native, Bin
        SynchronousNativeBinaryMessenger.setMessageHandler(1234, object : SynchronousBinaryMessageHandler {
            override fun onMessage(message: ByteBuffer?): ByteBuffer? {
                return ByteBuffer.wrap(ByteArray(1024 * 1024 * 5))
            }
        })

        // Sync, Native, Method
        synchronousChannel = SynchronousMethodChannel("flutter_native_channel_example")
        synchronousChannel.setMethodCallHandler(object : SynchronousMethodChannel.MethodCallHandler {
            override fun onMethodCall(call: MethodCall): SynchronousResult {
                return SynchronousResult.success(ByteArray(1024 * 1024 * 5))
            }
        })

        // Async, Native, Bin
        NativeBinaryMessenger.setMessageHandler(1234) { _, reply ->
            reply.reply(ByteBuffer.wrap(ByteArray(1024 * 1024 * 5)))
        }

        // Async, Native, Method
        nativeMethodChannel = NativeMethodChannel("flutter_native_channel_example")
        nativeMethodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // Async, Flutter, Method
        result.success(ByteArray(1024 * 1024 * 5))
    }
}
