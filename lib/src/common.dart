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
import 'dart:io';

/// The native library of channel.
final nativeLib = Platform.isIOS
    ? DynamicLibrary.process()
    : DynamicLibrary.open('libflutter_native_channel.so');

final registerFinalizer = nativeLib.lookupFunction<
    Void Function(Handle, Pointer<Uint8>, IntPtr),
    void Function(Object, Pointer<Uint8>, int)>("RegisterFinalizer");
