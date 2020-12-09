#include "jni_helper.h"

static jclass handle_message_from_dart_class = nullptr;
static jmethodID handle_message_from_dart_method = nullptr;

extern "C" struct SynchronousResultWrapper {
  int64_t length;
  uint8_t *data;
};

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct SynchronousResultWrapper *
SendSynchronousMessageToPlatform(int64_t channel, uint64_t length,
                                 uint8_t *data) {
  JniEnv env;

  if (handle_message_from_dart_class == nullptr) {
    handle_message_from_dart_class =
        (jclass) env->NewGlobalRef(JniHelper::FindClass(
            env,
            "io/xdea/flutter_native_channel/SynchronousNativeBinaryMessenger"));
    handle_message_from_dart_method = env->GetStaticMethodID(
        handle_message_from_dart_class, "handleMessageFromDart",
        "(JLjava/nio/ByteBuffer;)Ljava/nio/ByteBuffer;");
  }

  jobject message = env->NewDirectByteBuffer(data, length);
  jobject result = env->CallStaticObjectMethod(handle_message_from_dart_class,
                                               handle_message_from_dart_method,
                                               channel, message);

  auto ret = new struct SynchronousResultWrapper;
  if (result != nullptr) {
    ret->data = (uint8_t *) env->GetDirectBufferAddress(result);
    ret->length = env->GetDirectBufferCapacity(result);
  }

  // TODO: Handle GC.
  return ret;
}