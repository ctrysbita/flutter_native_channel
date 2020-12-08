#include "jni_helper.h"

static jclass handle_message_from_dart_class = nullptr;
static jmethodID handle_message_from_dart_method = nullptr;

extern "C" __attribute__((visibility("default"))) __attribute__((used))
uint8_t *SendSynchronizedMessageToPlatform(int64_t channel, uint32_t length, uint8_t *data) {
  JniEnv env;

  if (handle_message_from_dart_class == nullptr) {
    handle_message_from_dart_class = (jclass) env->NewGlobalRef(
        JniHelper::FindClass(env,
                             "io/xdea/flutter_native_channel/SynchronizedNativeBinaryMessenger"));
    handle_message_from_dart_method =
        env->GetStaticMethodID(
            handle_message_from_dart_class,
            "handleMessageFromDart",
            "(JLjava/nio/ByteBuffer;)Ljava/nio/ByteBuffer;");
  }

  jobject message = env->NewDirectByteBuffer(data, length);
  jobject result = env->CallStaticObjectMethod(handle_message_from_dart_class,
                                               handle_message_from_dart_method,
                                               channel, message);
  jbyte *ret = nullptr;
  jlong cap;
  if (result != nullptr) {
    ret = (jbyte *) env->GetDirectBufferAddress(result);
    cap = env->GetDirectBufferCapacity(result);
  }

  // TODO: Return capacity.
  // TODO: Handle GC.
  return (uint8_t *) ret;
}