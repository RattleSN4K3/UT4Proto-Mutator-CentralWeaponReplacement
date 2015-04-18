@echo off
echo.
echo Initialize
echo.

set /p BASEPATH="Enter UTGame folder: "

set SRCPATH=%BASEPATH%\Config
call InitConfig.bat

set SRCPATH=%BASEPATH%\Published\CookedPC
call :EnsureFolder %SRCPATH%
call InitContent.bat
set SRCPATH=%BASEPATH%\Unpublished\CookedPC
call :EnsureFolder %SRCPATH%
call InitContent.bat

set SRCPATH=%BASEPATH%\Src
call :EnsureFolder %SRCPATH%
call InitSources.bat


call InitList.bat
pause
goto :EOF


:EnsureFolder
if not exist "%*" mkdir "%*"
goto :EOF