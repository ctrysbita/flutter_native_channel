import 'dart:ffi';

import 'dart:io';

/// The native library of channel.
final nativeLib = Platform.isIOS
    ? DynamicLibrary.process()
    : DynamicLibrary.open('libflutter_native_channel.so');
