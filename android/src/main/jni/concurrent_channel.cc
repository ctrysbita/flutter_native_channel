#include <malloc.h>
#include <thread>
#include <vector>
#include <queue>
#include <algorithm>

#include "dart/dart_api_dl.h"
#include "jni_helper.h"

static jclass handle_message_from_dart_class_ = nullptr;
static jmethodID handle_message_from_dart_method_ = nullptr;

static Dart_Port_DL replyPort_;
static Dart_Port_DL messagePort_;

static std::mutex cv_mtx_;
static std::condition_variable cv_;
static std::vector<std::thread> threads_;

/**
 * @brief Represent a message in channel.
 */
extern "C" struct MessageWrapper {
  int64_t seq;
  int64_t length;
  uint8_t *data;
};

/**
 * @brief Represent a task for worker.
 */
struct TaskMessageWrapper {
  int64_t channel;
  struct MessageWrapper message;
};

static std::mutex message_queue_mtx_;
static std::queue<struct TaskMessageWrapper> message_queue_;

[[noreturn]] void SendMessageToPlatformWorker() {
  while (true) {
    {
      std::unique_lock<std::mutex> lck(cv_mtx_);
      cv_.wait(lck, []() { return !message_queue_.empty(); });
    }

    message_queue_mtx_.lock();
    auto msg = message_queue_.front();
    message_queue_.pop();
    message_queue_mtx_.unlock();

    JniEnv env;
    jobject message = env->NewDirectByteBuffer(msg.message.data, msg.message.length);
    env->CallStaticVoidMethod(handle_message_from_dart_class_,
                              handle_message_from_dart_method_, msg.channel, message,
                              msg.message.seq);
  }
}

FFI_EXPORT void InitializeChannel(void *data, int64_t replyPort, int64_t messagePort) {
  Dart_InitializeApiDL(data);
  replyPort_ = replyPort;
  messagePort_ = messagePort;

  if (handle_message_from_dart_class_ == nullptr) {
    JniEnv env;
    handle_message_from_dart_class_ =
        (jclass) env->NewGlobalRef(JniHelper::FindClass(
            env, "io/xdea/flutter_native_channel/ConcurrentNativeBinaryMessenger"));
    handle_message_from_dart_method_ = env->GetStaticMethodID(
        handle_message_from_dart_class_, "handleMessageFromDart",
        "(JLjava/nio/ByteBuffer;J)V");
  }

  auto concurrency = std::max(std::thread::hardware_concurrency() / 2, 1u);
  for (unsigned i = 0; i < concurrency; i++) {
    threads_.emplace_back(SendMessageToPlatformWorker);
  }
}

FFI_EXPORT void SendMessageToPlatform(int64_t channel, int64_t seq, int64_t length,
                                      uint8_t *data) {
  message_queue_mtx_.lock();
  message_queue_.push({channel, {seq, length, data}});
  message_queue_mtx_.unlock();

  cv_.notify_one();
}

extern "C" JNIEXPORT void
Java_io_xdea_flutter_1native_1channel_ConcurrentNativeBinaryMessenger_replyMessageToDart(
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