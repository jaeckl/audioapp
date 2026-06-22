@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
cmake -S engine_juce -B build/engine -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build/engine --target audioapp_engine