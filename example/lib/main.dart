import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_native_channel/flutter_native_channel.dart';

const channel = MethodChannel("flutter_native_channel_example");
final synchronousChannel =
    SynchronousMethodChannel("flutter_native_channel_example");

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int channelTs = 0;
  int synchronousChannelTs = 0;

  void handleTest() async {
    var ts = DateTime.now();
    for (var i = 0; i < 20; i++) {
      await channel.invokeMethod<dynamic>('MTD', 'ARG');
    }
    channelTs = DateTime.now().difference(ts).inMicroseconds;

    ts = DateTime.now();
    for (var i = 0; i < 20; i++) {
      synchronousChannel.invokeMethod<dynamic>('MTD', 'ARG');
    }
    synchronousChannelTs = DateTime.now().difference(ts).inMicroseconds;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Native Channel Test'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('20 * 5M via flutter channel: $channelTs us'),
            Text('20 * 5M via sync native channel: $synchronousChannelTs us'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.play_arrow),
          onPressed: handleTest,
        ),
      ),
    );
  }
}
