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

#include <dart/dart_api_dl.h>

#include "finalizer.h"
#include "jni_helper.h"

std::unordered_map<uint8_t *, jobject> Finalizer::global_references_;

void Finalizer::ReleaseGlobalReferenceByPointer(uint8_t *ptr) {
  auto object = global_references_[ptr];
  if (object != nullptr) {
    JniEnv env;
    env->DeleteGlobalRef(object);
    global_references_.erase(ptr);
    JniHelper::TriggerGC(env);
  }
}

void Finalizer::DartFinalizer(void *isolate_callback_data, void *peer) {
  ReleaseGlobalReferenceByPointer((uint8_t *) peer);
}

FFI_EXPORT void RegisterFinalizer(Dart_Handle handle,
                                  uint8_t *ptr,
                                  intptr_t external_allocation_size) {
  Dart_NewWeakPersistentHandle_DL(handle, ptr, external_allocation_size, Finalizer::DartFinalizer);
}