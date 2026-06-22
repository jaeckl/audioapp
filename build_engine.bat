@echo off
REM Activate MSVC and build the engine + JUCE tests with the correct toolchain.
REM IMPORTANT: builds into build\engine-msvc\ — never build\engine\ (GCC cache contamination).
REM See docs/guidelines/windows_android_setup.md §3 for details.

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

if errorlevel 1 (
    echo ERROR: vcvars64.bat failed. Is VS 2022 Build Tools installed?
    exit /b 1
)

REM Sanity gate — refuse to continue if cl.exe is not MSVC.
where cl.exe | findstr /I "MSVC\\Tools" >nul
if errorlevel 1 (
    echo ERROR: cl.exe is not from MSVC. MinGW / git-mingw is on PATH ahead of MSVC.
    echo See docs\guidelines\windows_android_setup.md section 13.1 for the cleanup recipe.
    exit /b 1
)

REM Configure (Ninja + MSVC, C++20, tests on).
cmake -S engine_juce -B build\engine-msvc -G Ninja -DCMAKE_BUILD_TYPE=Debug -DAUDIOAPP_BUILD_TESTS=ON
if errorlevel 1 exit /b 1

REM Build the JUCE test runner.
cmake --build build\engine-msvc --target audioapp_juce_tests
if errorlevel 1 exit /b 1

echo.
echo Build OK. Run tests with:
echo   .\build\engine-msvc\Debug\audioapp_juce_tests.exe
echo.
exit /b 0