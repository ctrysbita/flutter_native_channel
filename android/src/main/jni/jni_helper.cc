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

#include "jni_helper.h"

JavaVM *JniHelper::jvm_;
jobject JniHelper::class_loader_;
jmethodID JniHelper::find_class_method_;

void JniHelper::StoreClassLoader() {
  JniEnv env;
  auto random_class = env->FindClass(
      "io/xdea/flutter_native_channel/FlutterNativeChannelPlugin");
  auto class_class = env->GetObjectClass(random_class);
  auto class_loader_class = env->FindClass("java/lang/ClassLoader");
  auto get_class_loader_method = env->GetMethodID(class_class, "getClassLoader",
                                                  "()Ljava/lang/ClassLoader;");
  JniHelper::class_loader_ = env->NewGlobalRef(
      env->CallObjectMethod(random_class, get_class_loader_method));
  JniHelper::find_class_method_ = env->GetMethodID(
      class_loader_class, "findClass", "(Ljava/lang/String;)Ljava/lang/Class;");
}

jclass JniHelper::FindClass(JniEnv &env, const char *name) {
  return reinterpret_cast<jclass>(env->CallObjectMethod(
      JniHelper::class_loader_, JniHelper::find_class_method_,
      env->NewStringUTF(name)));
}

JniEnv::JniEnv() : env_{nullptr}, need_detach_{false} {
  if (JniHelper::jvm_->GetEnv((void **) &env_, JNI_VERSION_1_6) ==
      JNI_EDETACHED) {
    JniHelper::jvm_->AttachCurrentThread(&env_, nullptr);
    need_detach_ = true;
  }
}

JniEnv::~JniEnv() {
  if (need_detach_) JniHelper::jvm_->DetachCurrentThread();
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
  // Cache the JavaVM.
  JniHelper::jvm_ = vm;
  JniHelper::StoreClassLoader();

  return JNI_VERSION_1_6;
}
