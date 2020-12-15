#include <malloc.h>

#include "dart/dart_api_dl.h"
#include "jni_helper.h"

static jclass handle_message_from_dart_class_ = nullptr;
static jmethodID handle_message_from_dart_method_ = nullptr;
static Dart_Port_DL replyPort_;
static Dart_Port_DL messagePort_;

FFI_EXPORT void InitializeChannel(void *data, int64_t replyPort, int64_t messagePort) {
  Dart_InitializeApiDL(data);
  replyPort_ = replyPort;
  messagePort_ = messagePort;
}

extern "C" struct MessageWrapper {
  int64_t seq;
  int64_t length;
  uint8_t *data;
};

FFI_EXPORT void SendMessageToPlatform(int64_t channel, int64_t seq, uint64_t length,
                                      uint8_t *data) {
  JniEnv env;

  if (handle_message_from_dart_class_ == nullptr) {
    handle_message_from_dart_class_ =
        (jclass) env->NewGlobalRef(JniHelper::FindClass(
            env, "io/xdea/flutter_native_channel/NativeBinaryMessenger"));
    handle_message_from_dart_method_ = env->GetStaticMethodID(
        handle_message_from_dart_class_, "handleMessageFromDart",
        "(JLjava/nio/ByteBuffer;I)V");
  }

  jobject message = env->NewDirectByteBuffer(data, length);
  env->CallStaticVoidMethod(handle_message_from_dart_class_,
                            handle_message_from_dart_method_, channel, message,
                            seq);
}

extern "C" JNIEXPORT void
Java_io_xdea_flutter_1native_1channel_NativeBinaryMessenger_replyMessageToDart(
    JNIEnv *env, jclass clazz, jlong reply_id, jobject reply, jobject message) {
  // Free request message.
  if (message != nullptr) {
    free(env->GetDirectBufferAddress(message));
  }

  auto replyMessage = new MessageWrapper;
  replyMessage->seq = reply_id;
  if (reply != nullptr) {
    replyMessage->data =
        static_cast<uint8_t *>(env->GetDirectBufferAddress(reply));
    replyMessage->length = env->GetDirectBufferCapacity(reply);
  }

  Dart_PostInteger_DL(replyPort_, reinterpret_cast<int64_t>(replyMessage));

  // TODO: Handle GC.
}