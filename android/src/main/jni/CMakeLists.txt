cmake_minimum_required(VERSION 3.4.1)

add_library(
        flutter_native_channel
        # Sets the library as a shared library.
        SHARED
        # Provides a relative path to your source file(s).
        jni_helper.h
        jni_helper.cc
)
