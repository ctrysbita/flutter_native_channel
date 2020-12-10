import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

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
  static late NativeBinaryMessenger _instance;
  static NativeBinaryMessenger get instance =>
      _instance ?? NativeBinaryMessenger();

  /// The sequence number of messages that is used to identify result completer.
  static var _seq = 1;

  factory NativeBinaryMessenger([NativeBinaryMessenger? messenger]) {
    if (messenger != null) _instance = messenger;
    return _instance;
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

    var data = reply.ref.data;
    _resultCompleters[seq]?.complete(data);

    free(reply);
  }

  void onMessage(Pointer<MessageWrapper> message) async {}
}
