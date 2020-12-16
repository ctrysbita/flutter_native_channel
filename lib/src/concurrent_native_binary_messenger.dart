// Copyright 2020 Jason C.H <ctrysbita@outlook.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'common.dart';

final _resultCompleters = HashMap<int, Completer<Uint8List?>>();

final _initializeChannel = nativeLib.lookupFunction<
    Void Function(Pointer<Void>, Int64, Int64),
    void Function(Pointer<Void>, int, int)>("InitializeChannel");

final _sendConcurrentMessageToPlatform = nativeLib.lookupFunction<
    Void Function(Int64, Int64, Int64, Pointer<Uint8>),
    void Function(
        int, int, int, Pointer<Uint8>)>('SendConcurrentMessageToPlatform');

class MessageWrapper extends Struct {
  @Int64()
  external int seq;

  @Int64()
  external int length;

  external Pointer<Uint8> _data;
}

extension _MessageWrapperHelper on Pointer<MessageWrapper> {
  bool get isNull => ref._data.address == 0;

  Uint8List get data => ref._data.asTypedList(ref.length);
}

class ConcurrentNativeBinaryMessenger {
  static final _replyPort = ReceivePort();
  static final _messagePort = ReceivePort();

  static final ConcurrentNativeBinaryMessenger instance =
      ConcurrentNativeBinaryMessenger._();

  /// The sequence number of messages that is used to identify result completer.
  static var _seq = 1;

  /// Initialize channel and register callbacks.
  ConcurrentNativeBinaryMessenger._() {
    _initializeChannel(
      NativeApi.initializeApiDLData,
      _replyPort.sendPort.nativePort,
      _messagePort.sendPort.nativePort,
    );

    _replyPort.listen((dynamic msg) =>
        onReply(Pointer<MessageWrapper>.fromAddress(msg as int)));
    _messagePort.listen((dynamic msg) =>
        onMessage(Pointer<MessageWrapper>.fromAddress(msg as int)));
  }

  Future<Uint8List?> send(int channel, Uint8List? message) {
    var seq = _seq++;
    var completer = Completer<Uint8List?>();
    _resultCompleters[seq] = completer;

    var msgPtr = Pointer<Uint8>.fromAddress(0);
    var length = 0;
    if (message != null) {
      msgPtr = allocate<Uint8>(count: message.length);
      length = message.length;
      msgPtr.asTypedList(message.length).setAll(0, message);
    }

    _sendConcurrentMessageToPlatform(channel, seq, length, msgPtr);

    return completer.future;
  }

  void onReply(Pointer<MessageWrapper> wrappedResult) async {
    var seq = wrappedResult.ref.seq;
    assert(
      _resultCompleters.containsKey(seq),
      'Missing completer while receving result for seq $seq',
    );

    if (wrappedResult.isNull) {
      _resultCompleters.remove(seq)?.complete(null);
    } else {
      var data = wrappedResult.data;
      registerFinalizer(data, wrappedResult.ref._data);
      _resultCompleters.remove(seq)?.complete(data);
    }

    free(wrappedResult);
  }

  void onMessage(Pointer<MessageWrapper> message) async {
    throw UnimplementedError();
  }
}
