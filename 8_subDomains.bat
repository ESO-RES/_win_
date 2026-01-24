@echo off
setlocal EnableExtensions

REM ===============================================================
REM SubDomains.bat
REM Windows 8 built-in tools only (cmd + PowerShell 3.0)
REM From-scratch port of _20_subDomains.sh, with improvements:
REM   - Builds FQDNs from a wordlist: <subdomain>.<domain>
REM   - Ignores blank lines and comment lines (# or ;)
REM   - Trims whitespace around subdomain tokens
REM   - Optional: append, de-duplicate, lowercase
REM ===============================================================

set "DOMAIN="
set "INFILE="
set "OUTFILE=subDomainsList.txt"
set "APPEND=0"
set "DEDUPE=1"
set "LOWER=1"

:parse
if "%~1"=="" goto :parsedone
if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-?" goto :usage
if /I "%~1"=="--help" goto :usage

if /I "%~1"=="--domain" (set "DOMAIN=%~2" & shift & shift & goto :parse)
if /I "%~1"=="--in"     (set "INFILE=%~2" & shift & shift & goto :parse)
if /I "%~1"=="--out"    (set "OUTFILE=%~2" & shift & shift & goto :parse)
if /I "%~1"=="--append" (set "APPEND=1" & shift & goto :parse)
if /I "%~1"=="--no-dedupe" (set "DEDUPE=0" & shift & goto :parse)
if /I "%~1"=="--no-lower"  (set "LOWER=0" & shift & goto :parse)

REM Backwards-compatible positional args: SubDomains.bat example.com subDomains.txt
if not defined DOMAIN (
  set "DOMAIN=%~1"
  shift
  if "%~1"=="" goto :parsedone
  set "INFILE=%~1"
  shift
  goto :parse
)

echo [!] Unknown argument: %~1
goto :usage

:parsedone
if not defined DOMAIN goto :usage
if not defined INFILE goto :usage

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { " ^
  "  param($domain,$infile,$outfile,[int]$append,[int]$dedupe,[int]$lower) " ^
  "  $ErrorActionPreference='Stop' " ^
  "  if(-not (Test-Path -LiteralPath $infile)) { Write-Host ('[!] Input file not found: ' + $infile); exit 2 } " ^
  "  $dom = $domain.Trim(); if(-not $dom){ Write-Host '[!] Domain is empty.'; exit 2 } " ^
  "  if($lower -eq 1){ $dom = $dom.ToLowerInvariant() } " ^
  "  # Allow user to pass domain with trailing dot; normalize " ^
  "  if($dom.EndsWith('.')){ $dom = $dom.TrimEnd('.') } " ^
  "  $lines = Get-Content -LiteralPath $infile " ^
  "  $out = New-Object System.Collections.Generic.List[string] " ^
  "  foreach($ln in $lines){ " ^
  "    $t = $ln.Trim() " ^
  "    if(-not $t){ continue } " ^
  "    if($t.StartsWith('#') -or $t.StartsWith(';')){ continue } " ^
  "    # Remove inline comments after whitespace: 'api # comment' " ^
  "    if($t -match '^(.*?)\s+[;#].*$'){ $t = $Matches[1].Trim() } " ^
  "    if(-not $t){ continue } " ^
  "    if($lower -eq 1){ $t = $t.ToLowerInvariant() } " ^
  "    # strip trailing dot from token " ^
  "    if($t.EndsWith('.')){ $t = $t.TrimEnd('.') } " ^
  "    $out.Add(($t + '.' + $dom)) | Out-Null " ^
  "  } " ^
  "  if($dedupe -eq 1){ " ^
  "    $seen=@{}; $uniq = New-Object System.Collections.Generic.List[string]; " ^
  "    foreach($x in $out){ if(-not $seen.ContainsKey($x)){ $seen[$x]=$true; $uniq.Add($x) | Out-Null } } " ^
  "    $out = $uniq " ^
  "  } " ^
  "  if($append -eq 1){ $out | Out-File -LiteralPath $outfile -Encoding ascii -Append } " ^
  "  else { $out | Out-File -LiteralPath $outfile -Encoding ascii } " ^
  "  Write-Host ('[+] Wrote ' + $out.Count + ' entries to: ' + $outfile) " ^
  "}" ^
  " -domain '%DOMAIN%' -infile '%INFILE%' -outfile '%OUTFILE%' -append %APPEND% -dedupe %DEDUPE% -lower %LOWER%"

exit /b %ERRORLEVEL%

:usage
echo Build a subdomain wordlist from a prefix list.
echo.
echo Usage:
echo   %~nx0 DOMAIN INFILE [--out OUTFILE] [--append] [--no-dedupe] [--no-lower]
echo.
echo Or:
echo   %~nx0 --domain DOMAIN --in INFILE [--out OUTFILE] [--append] [--no-dedupe] [--no-lower]
echo.
echo Defaults:
echo   OUTFILE    = subDomainsList.txt
echo   Dedupe     = ON
echo   Lowercase  = ON
echo.
echo Examples:
echo   %~nx0 example.com subDomains.txt
echo   %~nx0 --domain test.com --in subDomains.txt --out subDomainsList.txt
echo   %~nx0 example.com subDomains.txt --append --no-dedupe
exit /b 1
