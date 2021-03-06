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

#include <algorithm>
#include <malloc.h>
#include <mutex>
#include <queue>
#include <thread>
#include <vector>

#include "dart/dart_api_dl.h"
#include "finalizer.h"
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

[[noreturn]] static void SendConcurrentMessageToPlatformWorker() {
  while (true) {
    {
      std::unique_lock<std::mutex> lock(cv_mtx_);
      cv_.wait(lock, []() { return !message_queue_.empty(); });
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

  // TODO: Dynamic concurrency.
  auto concurrency = std::max(std::thread::hardware_concurrency() / 2, 1u);
  for (unsigned i = 0; i < concurrency; i++) {
    threads_.emplace_back(SendConcurrentMessageToPlatformWorker);
  }
}

FFI_EXPORT void SendConcurrentMessageToPlatform(int64_t channel, int64_t seq, int64_t length,
                                                uint8_t *data) {
  {
    std::lock_guard<std::mutex> lock(message_queue_mtx_);
    message_queue_.push({channel, {seq, length, data}});
  }

  cv_.notify_one();
}

extern "C" JNIEXPORT void
Java_io_xdea_flutter_1native_1channel_ConcurrentNativeBinaryMessenger_replyMessageToDart(
    JNIEnv *env, jclass clazz, jlong reply_id, jobject reply, jobject message) {
  // Free request message.
  if (message != nullptr) {
    free(env->GetDirectBufferAddress(message));
  }

  auto ret = new MessageWrapper;
  ret->seq = reply_id;
  if (reply != nullptr) {
    ret->data =
        static_cast<uint8_t *>(env->GetDirectBufferAddress(reply));
    ret->length = env->GetDirectBufferCapacity(reply);
    Finalizer::AssociatePointerWithGlobalReference(ret->data, env->NewGlobalRef(reply));
  }

  Dart_PostInteger_DL(replyPort_, reinterpret_cast<int64_t>(ret));
}