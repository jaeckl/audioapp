@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
if errorlevel 1 (
    echo vcvars64 failed
    exit /b 1
)
cd /d "C:\Users\ludwi\Desktop\audioapp"
cmake --build build\engine --target audioapp_engine
exit /b %errorlevel%
