package io.xdea.flutter_native_channel_example

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.xdea.flutter_native_channel.SynchronousMethodChannel
import io.xdea.flutter_native_channel.SynchronousResult

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var synchronousChannel: SynchronousMethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter_native_channel_example")
        channel.setMethodCallHandler(this)
        synchronousChannel = SynchronousMethodChannel("flutter_native_channel_example")
        synchronousChannel.setMethodCallHandler(object : SynchronousMethodChannel.MethodCallHandler {
            override fun onMethodCall(call: MethodCall): SynchronousResult {
                return SynchronousResult.success(ByteArray(1024 * 1024 * 5))
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        result.success(ByteArray(1024 * 1024 * 5))
    }
}
