@echo off
setlocal
set "MUMMY_ENGINE=%GODOT4%"
if defined MUMMY_ENGINE if exist "%MUMMY_ENGINE%" goto engine_found
set "MUMMY_ENGINE=%~dp0..\runtime\Godot_v4.7.2-stable_win64.exe"
if exist "%MUMMY_ENGINE%" goto engine_found
set "MUMMY_ENGINE=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe"
if exist "%MUMMY_ENGINE%" goto engine_found
for %%G in (godot.exe godot4.exe Godot_v4.7.2-stable_win64.exe) do (
 for %%P in (%%G) do if not "%%~$PATH:P"=="" set "MUMMY_ENGINE=%%~$PATH:P"
)
if exist "%MUMMY_ENGINE%" goto engine_found
echo Open project.godot with Godot 4.7.2 and press F5.
echo Or set GODOT4 to the full path of your Godot executable.
pause
exit /b 1
:engine_found
"%MUMMY_ENGINE%" --headless --editor --import --path "%~dp0." --log-file "%~dp0import.log"
if errorlevel 1 exit /b 1
start "Mummy Workshop" "%MUMMY_ENGINE%" --path "%~dp0." --log-file "%~dp0playtest.log" %*
