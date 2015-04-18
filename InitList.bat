@echo off

echo.
echo List packages
echo.

:: List packages

for /F "tokens=1,2" %%a in (PACKAGES) do (
	if EXIST %%a echo ModPackages=%%b
)

echo.
pause
goto :EOF
