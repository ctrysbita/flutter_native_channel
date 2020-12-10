cmake_minimum_required(VERSION 3.4.1)

include_directories(include)

add_library(
        flutter_native_channel
        # Sets the library as a shared library.
        SHARED
        # Provides a relative path to your source file(s).
        include/dart/dart_api_dl.c
        jni_helper.h
        jni_helper.cc
        channel.cc
        synchronous_channel.cc
)
