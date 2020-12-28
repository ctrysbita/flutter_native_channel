/**
 * Copyright 2020 Jason C.H <ctrysbita@outlook.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "finalizer.h"
#include "jni_helper.h"

static jclass handle_message_from_dart_class_ = nullptr;
static jmethodID handle_message_from_dart_method_ = nullptr;

extern "C" struct SynchronousResultWrapper {
  int64_t length;
  uint8_t *data;
};

FFI_EXPORT struct SynchronousResultWrapper *
SendSynchronousMessageToPlatform(int64_t channel, uint64_t length,
                                 uint8_t *data) {
  JniEnv env;

  if (handle_message_from_dart_class_ == nullptr) {
    handle_message_from_dart_class_ =
        (jclass) env->NewGlobalRef(JniHelper::FindClass(
            env,
            "io/xdea/flutter_native_channel/SynchronousNativeBinaryMessenger"));
    handle_message_from_dart_method_ = env->GetStaticMethodID(
        handle_message_from_dart_class_, "handleMessageFromDart",
        "(JLjava/nio/ByteBuffer;)Ljava/nio/ByteBuffer;");
  }

  auto message = env->NewDirectByteBuffer(data, length);
  auto result = env->CallStaticObjectMethod(handle_message_from_dart_class_,
                                               handle_message_from_dart_method_,
                                               channel, message);

  auto ret = new struct SynchronousResultWrapper;
  if (result != nullptr) {
    ret->data = static_cast<uint8_t *>(env->GetDirectBufferAddress(result));
    ret->length = env->GetDirectBufferCapacity(result);
    Finalizer::AssociatePointerWithGlobalReference(ret->data, env->NewGlobalRef(result));
  }

  return ret;
}