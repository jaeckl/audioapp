@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1
if errorlevel 1 (
  echo FAIL vcvars
  pause
  exit /b 1
)
echo VCINIT OK
cd /d "C:\Users\ludwi\Desktop\audioapp\build\engine"
echo BUILDING...
ninja audioapp_juce_tests 2>&1
if errorlevel 1 (
  echo BUILD FAILED
  pause
  exit /b 1
)
echo BUILD_OK
