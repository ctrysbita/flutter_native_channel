import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_native_channel/flutter_native_channel.dart';

const channel = MethodChannel('flutter_native_channel_example');
final synchronousChannel =
    SynchronousMethodChannel('flutter_native_channel_example');
final concurrentChannel =
    ConcurrentMethodChannel('flutter_native_channel_example');

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
  int concurrentBinTs = 0;
  int concurrentChannelTs = 0;

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
            RaisedButton(
              child: Text('via flutter async bin: $binTs us'),
              onPressed: () async {
                var ts = DateTime.now();
                await Future.wait<dynamic>([
                  for (var i = 0; i < count; i++)
                    ServicesBinding.instance.defaultBinaryMessenger
                        .send('flutter_bin_channel', ByteData(5)),
                ]);
                binTs = DateTime.now().difference(ts).inMicroseconds;
                setState(() {});
              },
            ),
            RaisedButton(
              child: Text('via flutter async channel: $channelTs us'),
              onPressed: () async {
                var ts = DateTime.now();
                await Future.wait<dynamic>([
                  for (var i = 0; i < count; i++)
                    channel.invokeMethod<dynamic>('MTD', null),
                ]);
                channelTs = DateTime.now().difference(ts).inMicroseconds;
                setState(() {});
              },
            ),
            RaisedButton(
              child: Text('via concurrent native bin: $concurrentBinTs us'),
              onPressed: () async {
                var ts = DateTime.now();
                await Future.wait<dynamic>([
                  for (var i = 0; i < count; i++)
                    ConcurrentNativeBinaryMessenger.instance.send(1234, null),
                ]);
                concurrentBinTs = DateTime.now().difference(ts).inMicroseconds;
                setState(() {});
              },
            ),
            RaisedButton(
              child: Text(
                  'via concurrent native channel: $concurrentChannelTs us'),
              onPressed: () async {
                var ts = DateTime.now();
                await Future.wait<dynamic>([
                  for (var i = 0; i < count; i++)
                    concurrentChannel.invokeMethod<dynamic>('MTD', null),
                ]);
                concurrentChannelTs =
                    DateTime.now().difference(ts).inMicroseconds;
                setState(() {});
              },
            ),
            RaisedButton(
              child: Text('via sync native bin: $syncBinTs us'),
              onPressed: () async {
                var ts = DateTime.now();
                for (var i = 0; i < count; i++) {
                  SynchronousNativeBinaryMessenger().send(1234, null);
                }
                syncBinTs = DateTime.now().difference(ts).inMicroseconds;
                setState(() {});
              },
            ),
            RaisedButton(
              child: Text('via sync native channel: $syncChannelTs us'),
              onPressed: () async {
                var ts = DateTime.now();
                for (var i = 0; i < count; i++) {
                  synchronousChannel.invokeMethod<dynamic>('MTD', null);
                }
                syncChannelTs = DateTime.now().difference(ts).inMicroseconds;
                setState(() {});
              },
            ),
            RaisedButton(
              child: Text('Force GC'),
              onPressed: () => channel.invokeMethod<Null>('g'),
            ),
          ],
        ),
      ),
    );
  }
}
