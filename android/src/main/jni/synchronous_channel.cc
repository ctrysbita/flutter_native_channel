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
        (jclass)env->NewGlobalRef(JniHelper::FindClass(
            env,
            "io/xdea/flutter_native_channel/SynchronousNativeBinaryMessenger"));
    handle_message_from_dart_method_ = env->GetStaticMethodID(
        handle_message_from_dart_class_, "handleMessageFromDart",
        "(JLjava/nio/ByteBuffer;)Ljava/nio/ByteBuffer;");
  }

  jobject message = env->NewDirectByteBuffer(data, length);
  jobject result = env->CallStaticObjectMethod(handle_message_from_dart_class_,
                                               handle_message_from_dart_method_,
                                               channel, message);

  auto ret = new struct SynchronousResultWrapper;
  if (result != nullptr) {
    ret->data = static_cast<uint8_t *>(env->GetDirectBufferAddress(result));
    ret->length = env->GetDirectBufferCapacity(result);
  }

  // TODO: Handle GC.
  return ret;
}