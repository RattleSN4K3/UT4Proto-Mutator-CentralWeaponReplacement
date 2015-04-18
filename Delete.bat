@echo off
echo.
echo Deleting all symlinks
echo.

set /p BASEPATH="Enter UTGame folder: "
echo Continue?
pause >NUL

set UNINSTALL=1

set SRCPATH=%BASEPATH%\Config
call InitConfig.bat

set SRCPATH=%BASEPATH%\Published\CookedPC
call InitContent.bat
set SRCPATH=%BASEPATH%\Unpublished\CookedPC
call InitContent.bat

set SRCPATH=%BASEPATH%\Src
call InitSources.bat

pause
goto :EOF
