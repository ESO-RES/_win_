@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM socketPortScan.bat - Windows 8 (built-in tools) TCP port scanner
REM Authorized use only.

REM Defaults
set "HOST="
set "PORTS="
set "TIMEOUT=1.5"
set "WORKERS=100"

:parse
if "%~1"=="" goto :parsedone
if /I "%~1"=="-?" goto :usage
if /I "%~1"=="/?" goto :usage
if /I "%~1"=="--help" goto :usage
if /I "%~1"=="help" goto :usage

if /I "%~1"=="-H" (set "HOST=%~2" & shift & shift & goto :parse)
if /I "%~1"=="--host" (set "HOST=%~2" & shift & shift & goto :parse)
if /I "%~1"=="-P" (set "PORTS=%~2" & shift & shift & goto :parse)
if /I "%~1"=="--ports" (set "PORTS=%~2" & shift & shift & goto :parse)
if /I "%~1"=="--timeout" (set "TIMEOUT=%~2" & shift & shift & goto :parse)
if /I "%~1"=="--workers" (set "WORKERS=%~2" & shift & shift & goto :parse)

echo [!] Unknown argument: %~1
goto :usage

:parsedone
if not defined HOST goto :usage
if not defined PORTS goto :usage

REM Run scanner in PowerShell with args passed safely (prevents cmd quoting/injection issues).
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { param([string]$hostArg,[string]$portsArg,[string]$timeoutStr,[string]$workersStr) " ^
  "  try { " ^
  "    $ErrorActionPreference='Stop'; " ^
  "    function Fail([string]$msg,[int]$code=3){ Write-Host ('[!] ' + $msg); exit $code } " ^
  "    # Validate timeout " ^
  "    $tTmp = 0.0; if(-not [double]::TryParse($timeoutStr, [ref]$tTmp)){ Fail \"Invalid --timeout '$timeoutStr'\" 3 } " ^
  "    $timeout = [double]$timeoutStr; if($timeout -le 0){ Fail \"Invalid --timeout '$timeoutStr' (must be > 0)\" 3 } " ^
  "    # Validate workers " ^
  "    $wTmp = 0; if(-not [int]::TryParse($workersStr, [ref]$wTmp)){ Fail \"Invalid --workers '$workersStr'\" 3 } " ^
  "    $workers = [int]$workersStr; if($workers -lt 1){ Fail \"Invalid --workers '$workersStr' (must be >= 1)\" 3 } " ^
  "    # Practical clamp to avoid runaway resource use; silently clamp to keep output close. " ^
  "    if($workers -gt 500){ $workers = 500 } " ^
  "    function Parse-Ports([string]$s){ " ^
  "      $set=New-Object 'System.Collections.Generic.HashSet[int]'; " ^
  "      foreach($t in ($s -split ',')){ $t=$t.Trim(); if(-not $t){continue} " ^
  "        if($t -match '^\d+\-\d+$'){ " ^
  "          $a,$b=$t -split '-',2; $a=[int]$a; $b=[int]$b; if($a -gt $b){ Fail \"Invalid port range (start > end): $t\" 3 } " ^
  "          for($p=$a; $p -le $b; $p++){ if($p -lt 1 -or $p -gt 65535){ Fail \"Port out of range: $p\" 3 } [void]$set.Add($p) } " ^
  "        } elseif($t -match '^\d+$'){ " ^
  "          $p=[int]$t; if($p -lt 1 -or $p -gt 65535){ Fail \"Port out of range: $p\" 3 } [void]$set.Add($p) " ^
  "        } else { Fail \"Invalid port: $t\" 3 } " ^
  "      } " ^
  "      if($set.Count -eq 0){ Fail 'No ports provided' 3 } " ^
  "      $arr=$set.ToArray(); [Array]::Sort($arr); return $arr " ^
  "    } " ^
  "    $ports = Parse-Ports $portsArg; " ^
  "    try { $ip = [System.Net.Dns]::GetHostAddresses($hostArg) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1 } catch { $ip=$null } " ^
  "    if(-not $ip){ Write-Host \"[-] Cannot resolve '$hostArg': Unknown host\"; exit 2 } " ^
  "    $ipStr=$ip.IPAddressToString; " ^
  "    try { $name = [System.Net.Dns]::GetHostEntry($ipStr).HostName; if($name){ Write-Host \"[+] Scan Results for: $ipStr $name\" } else { Write-Host \"[+] Scan Results for: $ipStr\" } } catch { Write-Host \"[+] Scan Results for: $ipStr\" } " ^
  "    $workers = [Math]::Max(1, [Math]::Min($workers, $ports.Count)); " ^
  "    # RunspacePool for concurrency (PowerShell 3.0 compatible) " ^
  "    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault(); " ^
  "    $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1,$workers,$iss,$Host); " ^
  "    $pool.Open(); " ^
  "    $jobs = New-Object System.Collections.Generic.List[object]; " ^
  "    foreach($p in $ports){ " ^
  "      $ps = [PowerShell]::Create(); " ^
  "      $ps.RunspacePool = $pool; " ^
  "      [void]$ps.AddScript({ param($ip,$port,$timeout) " ^
  "        function Test-TcpPortLocal([string]$ip,[int]$port,[double]$timeoutSec){ " ^
  "          try { " ^
  "            $c=New-Object System.Net.Sockets.TcpClient; " ^
  "            $iar=$c.BeginConnect($ip,$port,$null,$null); " ^
  "            $ok=$iar.AsyncWaitHandle.WaitOne([int]([Math]::Ceiling($timeoutSec*1000)),$false); " ^
  "            if(-not $ok){ try{$c.Close()}catch{}; return [pscustomobject]@{Port=$port; Open=$false; Msg='timeout'} } " ^
  "            $c.EndConnect($iar); $c.Close(); return [pscustomobject]@{Port=$port; Open=$true; Msg='open'} " ^
  "          } catch [System.Net.Sockets.SocketException] { try{$c.Close()}catch{}; return [pscustomobject]@{Port=$port; Open=$false; Msg='closed'} } " ^
  "            catch { try{$c.Close()}catch{}; return [pscustomobject]@{Port=$port; Open=$false; Msg=('os error: ' + $_.Exception.GetType().Name)} } " ^
  "        } " ^
  "        Test-TcpPortLocal -ip $ip -port $port -timeoutSec $timeout " ^
  "      }).AddArgument($ipStr).AddArgument([int]$p).AddArgument($timeout); " ^
  "      $handle = $ps.BeginInvoke(); " ^
  "      $jobs.Add(@{PS=$ps; Handle=$handle}) | Out-Null; " ^
  "    } " ^
  "    foreach($j in $jobs){ " ^
  "      $res = $j.PS.EndInvoke($j.Handle); " ^
  "      $j.PS.Dispose(); " ^
  "      foreach($r in $res){ " ^
  "        if($r.Open){ Write-Host \"[+] $($r.Port)/tcp open\" } else { Write-Host \"[-] $($r.Port)/tcp $($r.Msg)\" } " ^
  "      } " ^
  "    } " ^
  "    $pool.Close(); $pool.Dispose(); " ^
  "  } catch { " ^
  "    Write-Host ('[!] ' + $_.Exception.Message); exit 3 " ^
  "  } " ^
  "} " ^
  " \"%HOST%\" \"%PORTS%\" \"%TIMEOUT%\" \"%WORKERS%\""

exit /b %ERRORLEVEL%

:usage
echo Usage:
echo   %~nx0 -H ^<host^> -P ^<ports^> [--timeout seconds] [--workers N]
echo.
echo Notes:
echo   - ports format: 80,443,1-1024
echo   - Windows 8 built-in tools only (cmd + PowerShell)
echo.
echo Examples:
echo   %~nx0 -H scanme.nmap.org -P 1-1024,8080,8443
echo   %~nx0 -H 192.168.1.1 -P 22,80,443 --timeout 1 --workers 50
exit /b 1
