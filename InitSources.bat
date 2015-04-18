@echo off

echo.
IF not DEFINED UNINSTALL echo Initialize symlink folders
IF DEFINED UNINSTALL echo Delete symlink folders
echo.

set RDBIN=rd
set LNBIN=mklink /D
set THISDIR=%~dp0

:: Ask for main path
set SKIP=
IF not {"%srcpath%"}=={""} set SKIP=1
IF {"%srcpath%"}=={""} set /p SRCPATH="Enter SRC folder: "

:: Check folder
IF {"%srcpath%"}=={""} goto :ErrorNoPath
IF NOT EXIST "%srcpath%" Goto :ErrorInvalidPath

:: Create symlinks
for /F "tokens=1,2" %%a in (PACKAGES) do (
	if EXIST %%a\Classes Call :Symlink %%a %%b
)

echo.
IF not DEFINED SKIP pause
goto :EOF


:Symlink
if DEFINED UNINSTALL (
	IF EXIST "%SRCPATH%\%2" (
		%RDBIN% "%SRCPATH%\%2"
	)
	goto :EOF
)

IF NOT EXIST "%SRCPATH%\%2" (
	%LNBIN% "%SRCPATH%\%2" "%THISDIR%%1"
) else (
	echo %2 already exists.
)
goto :EOF


:ErrorNoPath
echo.
echo Error. No path given.
echo.
pause
goto :EOF

:ErrorInvalidPath
echo.
echo Error. Invalid path given.
echo.
pause
goto :EOF