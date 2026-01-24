@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ===============================================================
REM GenFile-Fuzz.bat
REM Windows 8 built-in tools only (cmd.exe)
REM From-scratch port of _19_genFileFuzz.sh, with improvements:
REM   - Generates a wordlist like: work-0.txt ... work-100.jpg
REM   - Configurable prefix, range, extensions, and output path
REM ===============================================================

set "PREFIX=work-"
set "START=0"
set "END=100"
set "EXTS=txt,csv,pdf,jpg"
set "OUTFILE=genFilesList.txt"

:parse
if "%~1"=="" goto :parsedone
if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-?" goto :usage
if /I "%~1"=="--help" goto :usage

if /I "%~1"=="--prefix"  (set "PREFIX=%~2" & shift & shift & goto :parse)
if /I "%~1"=="--start"   (set "START=%~2"  & shift & shift & goto :parse)
if /I "%~1"=="--end"     (set "END=%~2"    & shift & shift & goto :parse)
if /I "%~1"=="--exts"    (set "EXTS=%~2"   & shift & shift & goto :parse)
if /I "%~1"=="--out"     (set "OUTFILE=%~2"& shift & shift & goto :parse)

echo [!] Unknown argument: %~1
goto :usage

:parsedone

REM Validate START/END
for /f "delims=0123456789" %%A in ("%START%") do (
  if not "%%A"=="" (echo [!] --start must be an integer. & exit /b 2)
)
for /f "delims=0123456789" %%A in ("%END%") do (
  if not "%%A"=="" (echo [!] --end must be an integer. & exit /b 2)
)
if %START% GTR %END% (
  echo [!] --start must be <= --end
  exit /b 2
)

REM Normalize extensions: remove spaces
set "EXTS=%EXTS: =%"

REM Create/overwrite output
> "%OUTFILE%" (
  for /L %%N in (%START%,1,%END%) do (
    for %%E in (!EXTS:,= !) do (
      echo %PREFIX%%%N.%%E
    )
  )
)

echo [+] Wrote wordlist: "%OUTFILE%"
echo     Prefix: %PREFIX%
echo     Range : %START%..%END%
echo     Exts  : %EXTS%
echo.
echo Example usage with fuzzers (not included with Windows by default):
echo   ffuf  -w "%OUTFILE%" -u http://HOST/files/FUZZ
echo   wfuzz --sc 200 -w "%OUTFILE%" http://HOST/files/FUZZ
exit /b 0

:usage
echo Generates a filename wordlist for fuzzing endpoints.
echo.
echo Usage:
echo   %~nx0 [--prefix P] [--start N] [--end N] [--exts list] [--out file]
echo.
echo Defaults (matches the original bash script):
echo   --prefix work-
echo   --start  0
echo   --end    100
echo   --exts   txt,csv,pdf,jpg
echo   --out    genFilesList.txt
echo.
echo Examples:
echo   %~nx0
echo   %~nx0 --prefix report- --start 1 --end 500 --exts txt,pdf --out files.txt
exit /b 1
