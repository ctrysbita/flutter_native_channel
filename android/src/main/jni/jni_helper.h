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

#pragma once

// Annotate functions that exported via dart FFI.
#define FFI_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

#include <jni.h>

class JniEnv {
 private:
  JNIEnv *env_;
  bool need_detach_;

  JniEnv(const JniEnv &) = delete;

  JniEnv &operator=(const JniEnv &) = delete;

 public:
  JniEnv();
  ~JniEnv();

  inline JNIEnv *operator->() {
    return env_;
  }
};

class JniHelper {
 private:
  static jclass system_class_;
  static jmethodID gc_method_;

 public:
  static JavaVM *jvm_;

  static jobject class_loader_;
  static jmethodID find_class_method_;

  static void StoreClassLoader();
  static jclass FindClass(JniEnv &env, const char *name);
  static void StoreGCMethod();
  static void TriggerGC(JniEnv &env);
};
