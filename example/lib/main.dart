import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_native_channel/flutter_native_channel.dart';

const channel = MethodChannel('flutter_native_channel_example');
final synchronousChannel =
    SynchronousMethodChannel('flutter_native_channel_example');
final nativeChannel = ConcurrentMethodChannel('flutter_native_channel_example');

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int sizeInKb = 1024;
  int count = 20;

  int binTs = 0;
  int channelTs = 0;
  int syncBinTs = 0;
  int syncChannelTs = 0;
  int asyncBinTs = 0;
  int asyncChannelTs = 0;

  void handleTest() async {
    var ts = DateTime.now();
    await Future.wait<dynamic>([
      for (var i = 0; i < count; i++)
        ServicesBinding.instance.defaultBinaryMessenger
            .send('flutter_bin_channel', ByteData(5)),
    ]);
    binTs = DateTime.now().difference(ts).inMicroseconds;

    setState(() {});

    ts = DateTime.now();
    await Future.wait<dynamic>([
      for (var i = 0; i < count; i++)
        channel.invokeMethod<dynamic>('MTD', null),
    ]);
    channelTs = DateTime.now().difference(ts).inMicroseconds;

    setState(() {});

    ts = DateTime.now();
    await Future.wait<dynamic>([
      for (var i = 0; i < count; i++)
        ConcurrentNativeBinaryMessenger.instance.send(1234, null),
    ]);
    asyncBinTs = DateTime.now().difference(ts).inMicroseconds;

    setState(() {});

    ts = DateTime.now();
    await Future.wait<dynamic>([
      for (var i = 0; i < count; i++)
        nativeChannel.invokeMethod<dynamic>('MTD', null),
    ]);
    asyncChannelTs = DateTime.now().difference(ts).inMicroseconds;

    setState(() {});

    ts = DateTime.now();
    for (var i = 0; i < count; i++) {
      await SynchronousNativeBinaryMessenger().send(1234, null);
    }
    syncBinTs = DateTime.now().difference(ts).inMicroseconds;

    setState(() {});

    ts = DateTime.now();
    for (var i = 0; i < count; i++) {
      synchronousChannel.invokeMethod<dynamic>('MTD', null);
    }
    syncChannelTs = DateTime.now().difference(ts).inMicroseconds;

    await Future<Null>.delayed(Duration(seconds: 1));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Native Channel Test'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            Text('Adjust Size (KBytes)'),
            Slider(
              value: sizeInKb.toDouble(),
              onChanged: (v) {
                setState(() => sizeInKb = v.toInt());
                channel.invokeMethod<Null>('s', v.toInt());
              },
              min: 1,
              max: 51200,
            ),
            Text('Adjust Count'),
            Slider(
              value: count.toDouble(),
              onChanged: (v) => setState(() => count = v.toInt()),
              min: 1,
              max: 30,
            ),
            Text('$count * $sizeInKb KB'),
            Text('via flutter bin: $binTs us'),
            Text('via flutter channel: $channelTs us'),
            Text('via sync native bin: $syncBinTs us'),
            Text('via sync native channel: $syncChannelTs us'),
            Text('via async native bin: $asyncBinTs us'),
            Text('via async native channel: $asyncChannelTs us'),
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
