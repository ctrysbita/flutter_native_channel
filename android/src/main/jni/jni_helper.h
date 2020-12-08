#pragma once

#include <jni.h>

class JniHelper {
 public:
  static JavaVM *jvm_;

  static jobject class_loader_;
  static jmethodID find_class_method_;

  static void StoreClassLoader();
  static jclass FindClass(const char *name);
};

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