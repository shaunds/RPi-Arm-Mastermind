cmake_minimum_required(VERSION 3.7.2)

PROJECT(Mastermind C ASM)
set (CMAKE_CXX_STANDARD 11)


add_executable(${PROJECT_NAME} master-mind.c lcdBinary.c "mm-matches.s")
