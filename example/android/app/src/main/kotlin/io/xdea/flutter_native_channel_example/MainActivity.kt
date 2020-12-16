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
    private lateinit var concurrentMethodChannel: ConcurrentMethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter_native_channel_example")
        channel.setMethodCallHandler(this)

        // Async, Flutter, Bin
        flutterEngine.dartExecutor.binaryMessenger.setMessageHandler("flutter_bin_channel") { _, reply ->
            reply.reply(ByteBuffer.allocateDirect(1024 * 1024 * 5))
        }

        // Sync, Native, Bin
        SynchronousNativeBinaryMessenger.setMessageHandler(1234,
                object : SynchronousNativeBinaryMessenger.SynchronousBinaryMessageHandler {
                    override fun onMessage(message: ByteBuffer?): ByteBuffer? {
                        return ByteBuffer.allocateDirect(1024 * 1024 * 5)
                    }
                }
        )

        // Sync, Native, Method
        synchronousChannel = SynchronousMethodChannel("flutter_native_channel_example")
        synchronousChannel.setMethodCallHandler(object : SynchronousMethodChannel.MethodCallHandler {
            override fun onMethodCall(call: MethodCall): SynchronousResult {
                return SynchronousResult.success(ByteArray(1024 * 1024 * 5))
            }
        })

        // Async, Native, Bin
        ConcurrentNativeBinaryMessenger.setMessageHandler(1234) { _, reply ->
            reply.reply(ByteBuffer.allocateDirect(1024 * 1024 * 5))
        }

        // Async, Native, Method
        concurrentMethodChannel = ConcurrentMethodChannel("flutter_native_channel_example")
        concurrentMethodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // Async, Flutter, Method
        result.success(ByteArray(1024 * 1024 * 5))
    }
}
