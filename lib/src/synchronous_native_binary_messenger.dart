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

import 'common.dart';

final _sendSynchronousMessageToPlatform = nativeLib.lookupFunction<
    Pointer<SynchronousResultWrapper> Function(Int64, Uint64, Pointer<Uint8>),
    Pointer<SynchronousResultWrapper> Function(
        int, int, Pointer<Uint8>)>('SendSynchronousMessageToPlatform');

class SynchronousResultWrapper extends Struct {
  @Int64()
  external int length;

  external Pointer<Uint8> _data;
}

extension _SynchronousResultWrapperHelper on Pointer<SynchronousResultWrapper> {
  bool get isNull => ref._data.address == 0;

  Uint8List get data => ref._data.asTypedList(ref.length);
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

    Uint8List? result;
    if (!wrappedResult.isNull) {
      result = wrappedResult.data;
      registerFinalizer(
        result,
        wrappedResult.ref._data,
        wrappedResult.ref.length,
      );
    }

    free(msgPtr);
    free(wrappedResult);

    return result;
  }
}
