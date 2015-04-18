@echo off

echo.
IF not DEFINED UNINSTALL echo Initialize symlink content files
IF DEFINED UNINSTALL echo Delete symlink content files
echo.

set RMBIN=del
set LNBIN=mklink
set THISDIR=%~dp0

:: Ask for main path
set SKIP=
IF not {"%srcpath%"}=={""} set SKIP=1
IF {"%srcpath%"}=={""} set /p SRCPATH="Enter CookedPC folder: "

:: Check folder
IF {"%srcpath%"}=={""} goto :ErrorNoPath
IF NOT EXIST "%srcpath%" Goto :ErrorInvalidPath

:: Create symlinks

for /D %%a in (*) do (
	IF EXIST %%a\Content call :symlinkpkgs %%a\Content
)

echo.
IF not DEFINED SKIP pause
goto :EOF


:symlinkpkgs
for %%b in (%1\*.upk) do (
	call :symlink %%b %%~nxb
)

goto :EOF

:Symlink
if DEFINED UNINSTALL (
	IF EXIST "%SRCPATH%\%2" (
		%RMBIN% "%SRCPATH%\%2"
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