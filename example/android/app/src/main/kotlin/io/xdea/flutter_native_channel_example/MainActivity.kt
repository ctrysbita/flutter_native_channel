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

    private var size = 1024 * 1024

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter_native_channel_example")
        channel.setMethodCallHandler(this)

        // Async, Flutter, Bin
        flutterEngine.dartExecutor.binaryMessenger.setMessageHandler("flutter_bin_channel") { _, reply ->
            reply.reply(ByteBuffer.allocateDirect(size))
        }

        // Sync, Native, Bin
        SynchronousNativeBinaryMessenger.setMessageHandler(1234,
                object : SynchronousNativeBinaryMessenger.SynchronousBinaryMessageHandler {
                    override fun onMessage(message: ByteBuffer?): ByteBuffer? {
                        return ByteBuffer.allocateDirect(size)
                    }
                }
        )

        // Sync, Native, Method
        synchronousChannel = SynchronousMethodChannel("flutter_native_channel_example")
        synchronousChannel.setMethodCallHandler(object : SynchronousMethodChannel.MethodCallHandler {
            override fun onMethodCall(call: MethodCall): SynchronousResult {
                return SynchronousResult.success(ByteArray(size))
            }
        })

        // Concurrent, Native, Bin
        ConcurrentNativeBinaryMessenger.setMessageHandler(1234) { _, reply ->
            reply.reply(ByteBuffer.allocateDirect(size))
        }

        // Concurrent, Native, Method
        concurrentMethodChannel = ConcurrentMethodChannel("flutter_native_channel_example")
        concurrentMethodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "s") {
            size = call.arguments as Int * 1024
            result.success(null)
            return
        }

        // Async, Flutter, Method
        result.success(ByteArray(size))
    }
}
