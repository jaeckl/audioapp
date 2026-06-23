call "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cd /d C:\Users\ludwi\Desktop\audioapp\build\engine
ninja audioapp_engine
exit /b %ERRORLEVEL%