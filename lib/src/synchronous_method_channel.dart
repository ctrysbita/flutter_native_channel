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

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_channel/src/synchronous_native_binary_messenger.dart';

/// A named channel for communicating with platform plugins using synchronous
/// method calls.
///
/// Method calls are encoded into binary before being sent, and binary results
/// received are decoded into Dart values. The [MethodCodec] used must be
/// compatible with the one used in the platform side. This can be achieved
/// by creating a method channel counterpart of this channel on the
/// platform side. The Dart type of arguments and results is `dynamic`,
/// but only values supported by the specified [MethodCodec] can be used.
/// The use of unsupported values should be considered programming errors, and
/// will result in exceptions being thrown. The null value is supported
/// for all codecs.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
class SynchronousMethodChannel {
  static int _computeChannelId(String name) {
    var channelMd5 = md5.convert(utf8.encode(name)).bytes;
    var channelDigest = 0;
    for (var i in channelMd5.take(8)) {
      channelDigest = channelDigest << 8 | i.toSigned(8);
    }
    return channelDigest;
  }

  /// Creates a [MethodChannel] with the specified [name].
  ///
  /// The [codec] used will be [StandardMethodCodec], unless otherwise
  /// specified.
  SynchronousMethodChannel(
    this.name, {
    int? id,
    this.codec = const StandardMethodCodec(),
    this.messenger = const SynchronousNativeBinaryMessenger(),
  }) : id = id ?? _computeChannelId(name);

  /// The logical channel on which communication happens, not null.
  final String name;

  /// The ID used by [SynchronousNativeBinaryMessenger].
  final int id;

  /// The message codec used by this channel, not null.
  final MethodCodec codec;

  /// The messenger that send the method call for result.
  final SynchronousNativeBinaryMessenger messenger;

  /// Invokes a [method] on this channel with the specified [arguments].
  ///
  /// The static type of [arguments] is `dynamic`, but only values supported by
  /// the [codec] of this channel can be used. The same applies to the returned
  /// result. The values supported by the default codec and their
  /// platform-specific counterparts are documented with [StandardMessageCodec].
  T? invokeMethod<T>(String method, [dynamic arguments]) {
    var encodedMethodCall =
        codec.encodeMethodCall(MethodCall(method, arguments));
    var message = encodedMethodCall.buffer
        .asUint8List(0, encodedMethodCall.lengthInBytes);
    var result = messenger.send(id, message);

    return result == null
        ? null
        : codec.decodeEnvelope(ByteData.view(result.buffer)) as T;
  }
}
