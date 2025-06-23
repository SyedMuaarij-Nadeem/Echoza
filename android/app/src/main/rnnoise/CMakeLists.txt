
cmake_minimum_required(VERSION 3.4.1)
add_library(rnnoise SHARED
    rnnoise.c
    rnn.c
    pitch.c
    vad.c
    kiss_fft.c)
include_directories(${CMAKE_SOURCE_DIR})
