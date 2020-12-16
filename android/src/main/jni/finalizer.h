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

#include <jni.h>
#include <unordered_map>

/**
 * @brief Finalizer that handling the lifecycle of object transmit using shared memory.
 */
class Finalizer {
 private:
  static std::unordered_map<uint8_t *, jobject> global_references_;

 public:
  /**
   * @brief Associate the inner pointer with global reference of java object.
   *
   * @param ptr The inner pointer of object. (e.g. java.nio.DirectByteBuffer)
   * @param ref The global reference of object.
   */
  static inline void AssociatePointerWithGlobalReference(uint8_t *ptr, jobject ref) {
    global_references_[ptr] = ref;
  }

  /**
   * Release the global reference of jobject associated with pointer.
   *
   * @param ptr Inner pointer of object.
   */
  static void ReleaseGlobalReferenceByPointer(uint8_t *ptr);

  /**
   * @brief Finalizer for dart VM.
   */
  static void DartFinalizer(void *isolate_callback_data, void *peer);
};
