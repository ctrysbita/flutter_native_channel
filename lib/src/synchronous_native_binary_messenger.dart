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

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'dynamic_library.dart';

final _sendSynchronousMessageToPlatform = nativeLib.lookupFunction<
    Pointer<SynchronousResultWrapper> Function(Int64, Uint64, Pointer<Uint8>),
    Pointer<SynchronousResultWrapper> Function(
        int, int, Pointer<Uint8>)>("SendSynchronousMessageToPlatform");

class SynchronousResultWrapper extends Struct {
  @Int64()
  external int length;

  external Pointer<Uint8> _data;

  Uint8List get data => _data.asTypedList(length);
}

class SynchronousNativeBinaryMessenger {
  const SynchronousNativeBinaryMessenger();

  /// Send a binary message to the platform on the given channel.
  ///
  /// Returns a [Pointer<Uint8>] of received response, undecoded, in binary
  /// form.
  Uint8List? send(int channel, Uint8List? message) {
    var msgPtr = Pointer<Uint8>.fromAddress(0);
    var length = 0;
    if (message != null) {
      msgPtr = allocate<Uint8>(count: message.length);
      length = message.length;
      msgPtr.asTypedList(message.length).setAll(0, message);
    }

    var wrappedResult =
        _sendSynchronousMessageToPlatform(channel, length, msgPtr);
    var result =
        wrappedResult.ref._data.address == 0 ? null : wrappedResult.ref.data;
    free(msgPtr);
    free(wrappedResult);
    return result;
  }
}
