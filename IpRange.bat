@echo off

setlocal EnableExtensions EnableDelayedExpansion



:: ============================================================

:: ipRange.bat

::

:: Simple IP range ping sweep for Windows 8+ (CMD only)

:: Default: prints ONLY responsive IP addresses

:: ============================================================



set QUIET=0

set COUNT_ONLY=0

set "OUTFILE="

set ADDRESS=



:: ---- Defaults ----

set START=1

set END=255

set TIMEOUT=500



:: ---- Parse args (options allowed anywhere) ----

:PARSE

if "%~1"=="" goto :VALIDATE



if /I "%~1"=="--help" goto :HELP

if /I "%~1"=="-h" goto :HELP

if "%~1"=="/?" goto :HELP



if /I "%~1"=="--quiet" (set QUIET=1 & shift & goto :PARSE)

if /I "%~1"=="-q"      (set QUIET=1 & shift & goto :PARSE)



if /I "%~1"=="--count" (set COUNT_ONLY=1 & shift & goto :PARSE)



if /I "%~1"=="--output" goto :PARSE_OUTPUT

if /I "%~1"=="-o"       goto :PARSE_OUTPUT



:: ---- Positional arguments ----

if not defined ADDRESS (

  set "ADDRESS=%~1" & shift & goto :PARSE

)

if "%START%"=="1" (

  set START=%~1 & shift & goto :PARSE

)

if "%END%"=="255" (

  set END=%~1 & shift & goto :PARSE

)

set TIMEOUT=%~1

shift

goto :PARSE



:PARSE_OUTPUT

shift

if "%~1"=="" exit /b 2

set "OUTFILE=%~1"

shift

goto :PARSE



:VALIDATE

if not defined ADDRESS goto :HELP



:: ---- Numeric validation ----

set /a _S=%START% >nul 2>nul || exit /b 2

set /a _E=%END% >nul 2>nul || exit /b 2

set /a _T=%TIMEOUT% >nul 2>nul || exit /b 2

set START=%_S%

set END=%_E%

set TIMEOUT=%_T%



:: ---- Bounds ----

if %START% LSS 1 exit /b 2

if %START% GTR 255 exit /b 2

if %END%   LSS 1 exit /b 2

if %END%   GTR 255 exit /b 2

if %START% GTR %END% exit /b 2

if %TIMEOUT% LSS 1 exit /b 2

if %TIMEOUT% GTR 60000 set TIMEOUT=60000



:: ---- Validate ADDRESS (exactly X.Y.Z) ----

set O1=

set O2=

set O3=

set O4=

for /f "tokens=1-4 delims=." %%A in ("%ADDRESS%") do (

  set O1=%%A

  set O2=%%B

  set O3=%%C

  set O4=%%D

)

if "%O1%"=="" exit /b 2

if "%O2%"=="" exit /b 2

if "%O3%"=="" exit /b 2

if not "%O4%"=="" exit /b 2

for %%O in (%O1% %O2% %O3%) do (

  set /a N=%%O 2>nul || exit /b 2

  if !N! LSS 0 exit /b 2

  if !N! GTR 255 exit /b 2

)



:: ---- Prepare output file ----

if defined OUTFILE ( > "%OUTFILE%" (type nul) || exit /b 2 )



set FOUND=0

set COUNT=0



:: ---- Ping sweep ----

for /L %%I in (%START%,1,%END%) do (

  ping -n 1 -w %TIMEOUT% %ADDRESS%.%%I >nul 2>&1

  if not errorlevel 1 (

    set FOUND=1

    set /a COUNT+=1

    if defined OUTFILE echo %ADDRESS%.%%I>>"%OUTFILE%"

    if %QUIET%==0 if %COUNT_ONLY%==0 echo %ADDRESS%.%%I

  )

)



if %QUIET%==0 if %COUNT_ONLY%==1 echo %COUNT%



endlocal & ( if "%FOUND%"=="1" (exit /b 0) else (exit /b 1) )



:HELP

echo.

echo ipRange.bat - IP range ping sweep

echo.

echo USAGE:

echo   ipRange.bat [options] ^<X.Y.Z^> [start] [end] [timeout_ms]

echo.

echo OPTIONS:

echo   --help ^| -h ^| /?        Show this help

echo   --quiet ^| -q            Suppress console output

echo   --count                 Print only total responsive hosts

echo   --output ^<file^> ^| -o    Write responsive IPs to file

echo.

exit /b 0

