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

import 'dynamic_library.dart';

final _resultCompleters = HashMap<int, Completer<Uint8List?>>();

final _sendMessageToPlatform = nativeLib.lookupFunction<
    Void Function(Int64, Int64, Uint64, Pointer<Uint8>),
    void Function(int, int, int, Pointer<Uint8>)>('SendMessageToPlatform');

class MessageWrapper extends Struct {
  @Int64()
  external int seq;

  @Int64()
  external int length;

  external Pointer<Uint8> _data;

  Uint8List get data => _data.asTypedList(length);
}

class NativeBinaryMessenger {
  static final _replyPort = ReceivePort();
  static final _messagePort = ReceivePort();

  static final NativeBinaryMessenger instance = NativeBinaryMessenger._();

  /// The sequence number of messages that is used to identify result completer.
  static var _seq = 1;

  /// Initialize channel and register callbacks.
  NativeBinaryMessenger._() {
    initializeChannel(
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

    _sendMessageToPlatform(channel, seq, length, msgPtr);

    return completer.future;
  }

  void onReply(Pointer<MessageWrapper> reply) async {
    var seq = reply.ref.seq;
    assert(
      _resultCompleters.containsKey(seq),
      'Missing completer while receving reply for seq $seq',
    );

    _resultCompleters[seq]
        ?.complete(reply.ref._data.address == 0 ? null : reply.ref.data);
    _resultCompleters.remove(seq);

    free(reply);
  }

  void onMessage(Pointer<MessageWrapper> message) async {}
}
