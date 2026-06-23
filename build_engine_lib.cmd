call "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1
set "PATH=C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.42.34433\bin\Hostx64\x64;%PATH%"
cd /d C:\Users\ludwi\Desktop\audioapp\build\engine
ninja audioapp_engine
exit /b %ERRORLEVEL%